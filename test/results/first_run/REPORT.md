
### Actionable defects

| Tool                        | Type       | Cause              | Explanation                                                                                     | Evidence           |
| --------------------------- | ---------- | ------------------ | ----------------------------------------------------------------------------------------------- | ------------------ |
| ai_reconnaissance_workflow  | MCP-SERVER | unknown            | tool call failed for `hexstrike-ai/ai_reconnaissance_workflow` (server-side failure recorded).  | JSONL:98, HR:396   |
| ai_vulnerability_assessment | MCP-SERVER | unknown            | tool call failed for `hexstrike-ai/ai_vulnerability_assessment` (server-side failure recorded). | JSONL:191, HR:871  |
| angr_symbolic_execution     | MCP-SERVER | other              | HTTP 500: `execute_command()` received unexpected keyword `timeout` (handler mismatch).         | JSONL:440, HR:2116 |
| arp_scan_discovery          | ENV        | missing_binary     | `arp-scan` not available in runtime; execution skipped.                                         | JSONL:333          |
| burpsuite_scan              | ENV        | other              | Burp API returned 404 from `http://127.0.0.1:8888/api/tools/burpsuite`.                         | JSONL:234, HR:1086 |
| clair_vulnerability_scan    | ENV        | unsupported_option | Flags not supported by installed `clairctl`.                                                    | JSONL:65, HR:256   |
| cloudmapper_analysis        | ENV        | unsupported_option | Missing required CloudMapper arguments/profile.                                                 | JSONL:39, HR:151   |
| docker_bench_security_scan  | ENV        | missing_binary     | `docker-bench-security` not present.                                                            | JSONL:61, HR:239   |
| kube_bench_cis              | ENV        | unsupported_option | Kubernetes context/mounts not provided.                                                         | JSONL:52, HR:214   |
| nuclei_scan                 | MCP-SERVER | unknown            | tool call failed for `nuclei_scan` (server-side).                                               | JSONL:226, HR:1101 |
| nuclei_templates_update     | MCP-SERVER | other              | Update routine blocked/unavailable in server sandbox.                                           | JSONL:228, HR:1116 |
| pacu_exploitation           | MCP-SERVER | other              | Server failed to initialize `pacu` environment.                                                 | JSONL:319, HR:1516 |
| prowler_scan                | ENV        | missing_binary     | `prowler` not found in PATH/pipx.                                                               | JSONL:281, HR:1251 |
| scout_suite_assessment      | ENV        | auth_failure       | Cloud profile/credentials missing.                                                              | JSONL:35, HR:131   |
| terrascan_iac_scan          | ENV        | io_failure         | Directory does not exist at provided path; scan aborted.                                        | JSONL:80, HR:316   |

---

### Noise / False Alarms – Not True

*(These are not code defects. They’re expected failures due to missing inputs, unreachable targets, or privilege requirements. Removed from actionable list.)*

| Tool                 | Type | Cause              | Explanation                                                         | Evidence           |
| -------------------- | ---- | ------------------ | ------------------------------------------------------------------- | ------------------ |
| binwalk_analyze      | ENV  | io_failure         | Cannot open input file (no file provided).                          | JSONL:420, HR:2016 |
| checksec_analyze     | ENV  | io_failure         | Missing ELF path (no target binary supplied).                       | JSONL:430, HR:2066 |
| dirsearch_scan       | ENV  | missing_binary     | Default wordlist path absent; provide wordlist or align image path. | JSONL:475, HR:2286 |
| dotdotpwn_scan       | ENV  | connect_refused    | Target refused connection during test.                              | JSONL:459, HR:2206 |
| feroxbuster_scan     | ENV  | io_failure         | Wordlist path unreadable/not mounted.                               | JSONL:19, HR:79    |
| gdb_peda_debug       | ENV  | io_failure         | Target executable not provided.                                     | JSONL:437, HR:2101 |
| gobuster_dir         | ENV  | io_failure         | Wordlist file not found.                                            | JSONL:2, HR:9      |
| gobuster_scan        | ENV  | unsupported_option | Wildcard target requires filters/exclusions.                        | JSONL:8, HR:29     |
| httpx_probe          | ENV  | io_failure         | Empty input list (no targets).                                      | JSONL:463, HR:2226 |
| iperf_network_test   | ENV  | connect_refused    | iperf server not reachable.                                         | JSONL:286, HR:1321 |
| katana_crawl         | ENV  | io_failure         | No seed URLs provided.                                              | JSONL:470, HR:2266 |
| libc_database_lookup | ENV  | io_failure         | No libc fingerprint given.                                          | JSONL:448, HR:2151 |
| nmap_scan            | ENV  | io_failure         | No target supplied.                                                 | JSONL:1, HR:1      |
| nmap_scan_udp        | ENV  | io_failure         | Raw sockets require privileges/capabilities.                        | JSONL:59, HR:229   |
| one_gadget_search    | ENV  | io_failure         | ELF/libc path not provided.                                         | JSONL:447, HR:2141 |
| pwninit_setup        | ENV  | io_failure         | Challenge binary missing.                                           | JSONL:444, HR:2131 |
| radare2_analyze      | ENV  | io_failure         | No input file for `r2`.                                             | JSONL:419, HR:2001 |
| ropgadget_search     | ENV  | io_failure         | Target binary missing.                                              | JSONL:427, HR:2051 |
| ropper_gadget_search | ENV  | io_failure         | No input binary for `ropper`.                                       | JSONL:428, HR:2056 |
| sslyze_scan          | ENV  | io_failure         | No hostnames provided.                                              | JSONL:468, HR:2256 |
| subfinder_enum       | ENV  | io_failure         | No root domain provided.                                            | JSONL:467, HR:2246 |
| theharvester_osint   | ENV  | io_failure         | No domain specified.                                                | JSONL:465, HR:2236 |
| trivy_fs_scan        | ENV  | io_failure         | Target path not mounted.                                            | JSONL:67, HR:261   |
| wafw00f_detect       | ENV  | io_failure         | No URL provided.                                                    | JSONL:466, HR:2241 |
| whatweb_fingerprint  | ENV  | io_failure         | No URL specified.                                                   | JSONL:471, HR:2271 |
| xsser_scan           | ENV  | missing_binary     | Python `cgi` module/dependency missing.                             | JSONL:464, HR:2236 |
| zgrab_banner         | ENV  | io_failure         | No input provided.                                                  | JSONL:469, HR:2261 |
| zmap_scan            | ENV  | io_failure         | Raw sockets need privileges; cannot scan.                           | JSONL:460, HR:2211 |

> Note on **wfuzz_scan**: I excluded all earlier speculation. Your logs show `error(mcp_server)` for the tool call, but without server stderr I cannot reach ≥99% root-cause. It’s **not** a false “wordlist/path” issue. If you want it listed as actionable, include a fresh run’s JSON or server stderr; otherwise I keep it out of the noise and out of confirmed defects.

---

### Needs Evidence (to reach ≥99% confidence)

*(Return server JSON: `success`, `return_code`, `stderr` and a few lines of `stdout` to finalize classification.)*

| Tool                     | Type | Cause           | Explanation                                                        | Evidence           |
| ------------------------ | ---- | --------------- | ------------------------------------------------------------------ | ------------------ |
| ai_generate_attack_suite | ?    | other           | `name 'self' is not defined` (truncated).                          | JSONL:186, HR:846  |
| ai_generate_payload      | ?    | schema_mismatch | AI payload generation request malformed; schema mismatch.          | JSONL:246, HR:1201 |
| checkov_iac_scan         | ?    | other           | Path skipped / directory missing in sandbox; details insufficient. | JSONL:76           |
| enum4linux_ng_advanced   | ?    | invalid_input   | `unrecognized arguments: S,U,G,P`.                                 | JSONL:318, HR:1506 |
| http_framework_test      | ?    | other           | `'str' object has no attribute 'get'`.                             | JSONL:132, HR:571  |
| rustscan_fast_scan       | ?    | invalid_input   | `invalid value '1-1024...': invalid digit found in string`.        | JSONL:288, HR:1356 |

