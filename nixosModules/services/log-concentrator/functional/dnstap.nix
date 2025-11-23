/**
  Aggregate `dnstap` logs from nodes
*/
{ lib, ... }:
let
  dnsIps =
    [
      "dns_1"
      "dns_2"
    ]
    |> map (lib.homelab.getServiceHost)
    |> map (lib.flip lib.homelab.getHostIpInNetwork "backbone-inner");

  inherit (lib.homelab.getServiceConfig "log-concentrator") dnstapPort;
in
{
  services.vector.settings = {
    sources.dnstap-concentrator = {
      type = "vector";
      address = "0.0.0.0:${dnstapPort |> toString}";
      # See the private mixin for the write portion
    };

    transforms.dnstap-remap = {
      type = "remap";
      inputs = [ "dnstap-concentrator" ];
      source = # vrl
        ''
          .timestamp = from_unix_timestamp!(.time, unit: "nanoseconds")

          # Network details
          .client_ip = .sourceAddress
          .client_port = .sourcePort
          .responder_ip = .responseAddress
          .responder_port = .responsePort
          .socket_family = .socketFamily
          .socket_protocol = .socketProtocol

          # Message details
          .message_type = .messageType
          .rcode = .responseData.rcodeName || "UNKNOWN"

          # Extract Flags
          .flag_qr = .responseData.header.qr
          .flag_aa = .responseData.header.aa
          .flag_tc = .responseData.header.tc
          .flag_rd = .responseData.header.rd
          .flag_ra = .responseData.header.ra

          # Extract Question (Take the first one)
          q = .responseData.question[0]
          .question_name = q.domainName
          .question_type = q.questionType
          .question_class = q.class

          # Extract Answers (Parallel Arrays)
          # Map the array of objects into arrays of primitives
          answers = []
          if exists(.responseData.answers) && is_array(.responseData.answers) {
              answers = array!(.responseData.answers);
          }

          .answer_names = map_values(answers) -> |v| { v.domainName || "" }
          .answer_types = map_values(answers) -> |v| { v.recordType || "" }
          .answer_rdata = map_values(answers) -> |v| { v.rData || "" }

          # Remove original nested JSON to keep payload clean
          del(.responseData)
          del(.dataType)
          del(.dataTypeId)
          del(.messageTypeId)
          del(.responseAddress)
          del(.responsePort)
          del(.sourceAddress)
          del(.sourcePort)
          del(.source_type)
          del(.time) # Used the ISO timestamp
          del(.timePrecision)
        '';
    };
  };

  # Firewall
  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" ip saddr {${
      dnsIps |> lib.concatStringsSep ", "
    }} tcp dport ${dnstapPort |> toString} accept
  '';
}
