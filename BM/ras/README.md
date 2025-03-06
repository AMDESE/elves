# RAS
AMD EYPC processor Scalable family supports various Reliability, Availability, and Serviceability (RAS) features across various generations of ZEN product series. Currently, BM/ras covers RAS MCE / MCA tests present in the kernel.

# MCE / MCA test cases
- Machine Check Architecture (MCA) is an AMD mechanism in which the CPU reports hardware errors to the operating system.
- Machine check exception (MCE) is a type of error that occurs when a problem involving the hardware is detected.
- **mce\_mca:** Covers RAS mce, mca tests, the details can be found in [mce\_mca/README.md](mce\_mca/README.md).
