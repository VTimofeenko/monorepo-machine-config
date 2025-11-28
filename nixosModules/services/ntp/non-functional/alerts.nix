{
  Emergency = [
    {
      title = "NTP is not synchronized";
      query = "ntp_system_leap_indicator == 3";
      description = "Leap indicator is 3 (alarm/unsync)";
    }
  ];
  Warning = [
    {
      title = "High NTP offset";
      query = "abs(ntp_source_offset_seconds) > 0.05";
    }
    {
      title = "High NTP send error rate";
      query = "rate(ntp_server_response_send_errors_total[5m]) > 0";
    }
    {
      title = "System clock is stepping";
      query = "rate(ntp_system_accumulated_steps_seconds[5m]) > 0";
    }
  ];
}
