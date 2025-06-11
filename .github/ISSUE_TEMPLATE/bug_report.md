---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

** Describe the bug **
A clear and concise description of the bug. Report exact testcase which is erroring out in your environment.

** Environment **
Specify whether the test case errors out on Bare Metal (BM) or Virtualization (Virt).
- Platform: [Bare Metal (BM) or Virtualization (Virt)]

** Steps to reproduce **
Steps to reproduce the behavior, including a reproducible example whenever possible.

** Expected behavior **
A clear and concise description of what you expected to happen.

** Current behavior **
A clear and concise description of what is currently happening.

** System information **
- Platform: [Bare Metal (BM) or Virtualization (Virt)]
- OS: [e.g., output of `lsb_release -a`]
- Kernel: [e.g., output of `uname -r`]
- Elves tag/branch/version: [e.g., elves_05_2025 or master branch]
- In case of Virt:
     Guest kernel version:
     Guest Base OS:
     QEMU version:
     OVMF/edk2 version:
- Hardware platform: [e.g., AMD EPYC processors Family 1Ah (codenamed "Turin")]

** Additional information **
Provide any additional details about the problem here, such as test details, logs, or screenshots.
- Debug log: Specific testcase error logs.
	e.g., `job-2025-06-06T14.44-7194a44.tar.gz` from `elves/results/job-2025-06-06T14.44-7194a44/test-results/<testcase directory>`.
