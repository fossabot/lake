Feature: Metrics test

  Scenario: metrics have expected keys
    Given lake is configured with
      | property            | value |
      | METRICS_REFRESHRATE |    1s |

    Then metrics file reports/blackbox-tests/metrics/metrics.json should have following keys:
      | key             |
      | messageEgress   |
      | messageIngress  |
      | memoryAllocated |
    And metrics file reports/blackbox-tests/metrics/metrics.json has permissions -rw-r--r--

  Scenario: metrics can remembers previous values after reboot
    Given lake is configured with
      | property            | value |
      | METRICS_REFRESHRATE |    1s |

    Then metrics file reports/blackbox-tests/metrics/metrics.json reports:
      | key            | value |
      | messageEgress  |     0 |
      | messageIngress |     0 |

    When lake recieves "A B"
    Then lake responds with "A B"
    And metrics file reports/blackbox-tests/metrics/metrics.json reports:
      | key            | value |
      | messageEgress  |     1 |
      | messageIngress |     1 |

    When restart unit "lake-relay.service"
    Then metrics file reports/blackbox-tests/metrics/metrics.json reports:
      | key            | value |
      | messageEgress  |     1 |
      | messageIngress |     1 |
