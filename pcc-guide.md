#  Private Cloud Compute Security Guide
A new frontier for AI privacy in the cloud.
![](pcc-guide/private-cloud-compute-header~dark@2x.png)

![](pcc-guide/private-cloud-compute-subhead~dark@2x.png)
Private Cloud Compute (PCC) delivers groundbreaking privacy and security protections to support computationally intensive requests for Apple Intelligence by bringing our industry-leading device security model into the cloud. Whenever possible, Apple Intelligence processes tasks locally on device, but more sophisticated tasks require additional processing power to execute more complex foundation models in the cloud. Private Cloud Compute makes it possible for users to take advantage of such models without sacrificing the security and privacy that they expect from Apple devices.
We designed Private Cloud Compute with core requirements that go beyond traditional models of cloud AI security:
**Stateless computation on personal user data**: PCC must use the personal user data that it receives exclusively for the purpose of fulfilling the user’s request. User data must not be accessible after the response is returned to the user.
**Enforceable guarantees**: It must be possible to constrain and analyze all the components that critically contribute to the guarantees of the overall PCC system.
**No privileged runtime access**: PCC must not contain privileged interfaces that might enable Apple site reliability staff to bypass PCC privacy guarantees.
**Non-targetability**: An attacker should not be able to attempt to compromise personal data that belongs to specific, targeted PCC users without attempting a broad compromise of the entire PCC system.
**Verifiable transparency**: Security researchers need to be able to verify, with a high degree of confidence, that our privacy and security guarantees for PCC match our public promises.

This guide is designed to walk you through these requirements and provide the resources you need to verify them for yourself, including a comprehensive look at the technical design of PCC and the specific implementation details needed to validate it.
### Core Security & Privacy Requirements
Dive into understanding PCC by learning about the extraordinary security requirements of the system.
[Overview](https://security.apple.com/documentation/private-cloud-compute/corerequirements#overview)
We designed Private Cloud Compute with core requirements that go beyond traditional models of cloud AI security.
**[Stateless computation on personal user data](https://security.apple.com/documentation/private-cloud-compute/corerequirements#Stateless-computation-on-personal-user-data)**
Private Cloud Compute must use the personal user data that it receives exclusively for the purpose of fulfilling the user’s request. User data must never be available to anyone other than the user, not even to Apple staff, not even during active processing. And user data must not be retained, including via logging or for debugging, after the response is returned to the user.
For certain use cases, the user’s device may in the future permit PCC to cache user data for a limited amount of time for use in subsequent PCC requests. In that case, PCC’s statelessness will be preserved through cryptographic key control; PCC will cache data encrypted with a key provided by the user’s device, and will wipe its own copy of that key after the request. PCC will therefore only be able to decrypt the cached data if the user’s device sends another request that includes the cache decryption key.
*To learn more about this requirement, see ~[Stateless Computation and Enforceable Guarantees](https://security.apple.com/documentation/private-cloud-compute/statelessandenforcable)~.*
**[Enforceable guarantees](https://security.apple.com/documentation/private-cloud-compute/corerequirements#Enforceable-guarantees)**
Security and privacy guarantees are strongest when they are entirely technically enforceable, which means it must be possible to constrain and analyze all the components that critically contribute to the guarantees of the overall Private Cloud Compute system. For example, it’s very difficult to reason about what a TLS-terminating load balancer might do with user data during a debugging session, so PCC must not depend on such external components for its core security and privacy guarantees. Similarly, operational requirements such as collecting server metrics and error logs must be supported with mechanisms that do not undermine privacy protections.
*To learn more about this requirement, see ~[Stateless Computation and Enforceable Guarantees](https://security.apple.com/documentation/private-cloud-compute/statelessandenforcable)~.*
**[No privileged runtime access](https://security.apple.com/documentation/private-cloud-compute/corerequirements#No-privileged-runtime-access)**
Private Cloud Compute must not contain privileged interfaces that might enable Apple site reliability staff to bypass PCC privacy guarantees, even when working to resolve an outage or other severe incident. This also means that PCC must not support a mechanism by which the privileged access envelope could be enlarged at runtime, such as by loading additional software.
*To learn more about this requirement, see ~[No Privileged Runtime Access](https://security.apple.com/documentation/private-cloud-compute/noprivilegedaccess)~.*
**[Non-targetability](https://security.apple.com/documentation/private-cloud-compute/corerequirements#Non-targetability)**
An attacker should not be able to attempt to compromise personal data that belongs to specific, targeted Private Cloud Compute users without attempting a broad compromise of the entire PCC system. This must hold true even for exceptionally sophisticated attackers who can attempt *physical* attacks on PCC nodes in the supply chain or attempt to obtain malicious access to PCC data centers. In other words, a limited PCC compromise must not allow the attacker to steer requests from specific users to compromised nodes; targeting users should require a wide attack that’s likely to be detected. To understand this more intuitively, contrast it with a traditional cloud service design where every application server is provisioned with database credentials for the entire application database, so a compromise of a single application server is sufficient to access any user’s data, even if that user doesn’t have any active sessions with the compromised application server.
*To learn more about this requirement, see ~[Non-Targetability](https://security.apple.com/documentation/private-cloud-compute/nontargetability)~.*
**[Verifiable transparency](https://security.apple.com/documentation/private-cloud-compute/corerequirements#Verifiable-transparency)**
Security researchers need to be able to verify, with a high degree of confidence, that our privacy and security guarantees for Private Cloud Compute match our public promises. We already have an earlier requirement for our guarantees to be enforceable. Hypothetically, then, if security researchers had sufficient access to the system, they would be able to verify the guarantees. But this last requirement, verifiable transparency, goes one step further and does away with the hypothetical: security researchers *must be able to verify* the security and privacy guarantees of Private Cloud Compute, and they *must be able to verify* that the software that’s running in the PCC production environment is the same as the software they inspected when verifying the guarantees.
*To learn more about this requirement, see ~[Verifiable Transparency](https://security.apple.com/documentation/private-cloud-compute/verifiabletransparency)~.*
### Stateless Computation and Enforceable Guarantees
The PCC node is designed to safeguard user data and enforce it is not retained once request processing is complete.
[Overview](https://security.apple.com/documentation/private-cloud-compute/statelessandenforcable#overview)
![](pcc-guide/overview~dark@2x.png)
The trust boundary in PCC is our compute node: ~[custom-built server hardware](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Hardware-design)~ that brings the power and security of Apple silicon to the data center, with the same hardware security technologies we use in iPhone. We paired this hardware with ~[a new operating system](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations)~: a hardened subset of the foundations of iOS and macOS tailored to support large language model (LLM) inference workloads while presenting an extremely narrow attack surface. On top of this foundation, we built ~[a custom set of cloud extensions](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Private-Cloud-Support-cryptex)~ with privacy in mind. This set includes PCC’s ~[secure request processing infrastructure](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Request-handling)~ and ~[a new machine learning stack](https://security.apple.com/documentation/private-cloud-compute/statelessinference)~ specifically for hosting ~[our cloud-based foundation model](https://machinelearning.apple.com/research/introducing-apple-foundation-models)~.
We designed PCC to make several guarantees about the way it handles user data:
A user’s device sends data to PCC for the sole, exclusive purpose of fulfilling the user’s inference request. PCC uses that data only to perform the operations requested by the user.
User data is encrypted directly to the PCC nodes that are processing the request, and the decrypted user data is retained only until the response is returned.
User data is never available to Apple — even to staff with administrative access to the production service or hardware.
When Apple Intelligence needs to draw on Private Cloud Compute, it ~[constructs a request](https://security.apple.com/documentation/private-cloud-compute/requestflow#Apple-Intelligence-orchestration)~ — consisting of the prompt, plus the desired model and inferencing parameters — that serves as input to the cloud model. The PCC client on the user’s device then ~[encrypts this request](https://security.apple.com/documentation/private-cloud-compute/requesthandling)~directly to the public keys of the PCC nodes that it first confirms are valid and ~[cryptographically certified](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Certificate-ceremony-process)~. This provides end-to-end encryption from the user’s device to the validated PCC nodes, ensuring the request cannot be accessed in transit by anything outside those highly protected PCC nodes. Supporting data center services, such as load balancers and privacy gateways, run outside of this trust boundary and do not have the keys required to decrypt the user’s request, thus contributing to our enforceable guarantees.
Next, we must protect the integrity of the PCC node and prevent any tampering with the keys used by PCC to decrypt user requests. The system uses ~[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)~ and ~[restrictive code-signing policies](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Code-Signing)~ for an enforceable guarantee that only authorized and cryptographically measured code is executable on the node. All code that can run on the node must be part of a trust cache that has been signed by Apple, approved for that specific PCC node, and loaded by the Secure Enclave such that it cannot be changed or amended at runtime. The PCC node uses ~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~ to further limit executable code, and therefore attack surface, once user data is present on the node. Additionally, all code and model assets are delivered using ~[Cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~ which leverage the same integrity protection that powers the ~[Signed System Volume](https://support.apple.com/guide/security/signed-system-volume-security-secd698747c9/web)~. Finally, the Secure Enclave provides an enforceable guarantee that the keys used to decrypt requests cannot be duplicated or extracted.
The Private Cloud Compute software stack is designed to ensure that user data is not leaked outside the trust boundary or retained once a request is complete, even in the presence of implementation errors. The PCC node’s ~[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)~ means that Secure Enclave randomizes the data volume’s encryption keys on every boot *and does not persist these random keys*, ensuring that data written to the data volume cannot be retained across reboot. In other words, there is an enforceable guarantee that the data volume is cryptographically erased every time the PCC node’s Secure Enclave Processor reboots.
~[The inference engine](https://security.apple.com/documentation/private-cloud-compute/statelessinference#The-Inference-Engine)~ on the PCC node is designed to delete data associated with a request upon completion, and the address spaces that are used to handle user data are periodically recycled to limit the impact of any data that might be unexpectedly retained in memory. To process requests with reduced latency and higher throughput, PCC supports ~[distributed inference](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Distributed-inference)~ across multiple PCC nodes. To ensure that user data is not leaked outside the trust boundary of the PCC node, ~[ensemble attestation](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Ensemble-attestation)~ enables these groups of PCC nodes to mutually authenticate each other while negotiating a shared secret to encrypt all user data in transit.
Finally, for our enforceable guarantees to be meaningful, we also need to protect against exploitation that might bypass these guarantees. Technologies such as ~[Pointer Authentication Codes](https://support.apple.com/guide/security/operating-system-integrity-sec8b776536b/1/web/1#sec0167b469d)~ and ~[sandboxing](https://support.apple.com/guide/security/security-of-runtime-process-sec15bfe098e/1/web/1)~act to resist such exploitation and limit an attacker’s horizontal movement within the PCC node. The ~[request handling](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Request-handling)~ and ~[inference dispatch](https://security.apple.com/documentation/private-cloud-compute/statelessinference#The-Inference-Engine)~ layers are written in Swift, ensuring memory safety, and use separate address spaces to isolate initial processing of requests. This combination of memory safety and the principle of least privilege removes entire classes of attacks on the inference stack itself and limits the level of control and capability that a successful attack can obtain.
### No Privileged Runtime Access
PCC is designed without privileged interfaces that might expose user data.
[Overview](https://security.apple.com/documentation/private-cloud-compute/noprivilegedaccess#overview)
We designed Private Cloud Compute to ensure that privileged access doesn’t allow anyone to bypass our stateless computation guarantees. When building the PCC node software, we excluded components that are traditionally critical to data-center administration, such as remote shells and system introspection and observability tools. We replaced those general-purpose software components with components that are purpose-built to deterministically provide only a small, restricted set of operational metrics to SRE staff.
We also ~[did not include remote shell](https://security.apple.com/documentation/private-cloud-compute/management)~ or interactive debugging mechanisms on the PCC node. Our code-signing machinery prevents such mechanisms from loading additional code, but this sort of open-ended access would provide a broad attack surface to subvert the system’s security or privacy. Beyond simply not including a shell, remote or otherwise, PCC nodes cannot enable Developer Mode and do not include the tools needed by debugging workflows.
We built the system’s observability and management tooling with privacy safeguards that are designed to prevent user data from being exposed. For example, the system doesn’t include a general-purpose logging mechanism. Instead, ~[only pre-specified, structured, and audited logs and metrics can leave the node](https://security.apple.com/documentation/private-cloud-compute/management#Log-filtering)~, and multiple independent layers of review help prevent user data from accidentally being exposed through these mechanisms. With traditional cloud AI services, such mechanisms might allow someone with privileged access to observe or collect user data.
Together, these techniques provide enforceable guarantees that only specifically designated code has access to user data, and that user data cannot leak outside the PCC node during system administration.

### Non-Targetability
PCC is designed to ensure that an attacker cannot target specific PCC users.
[Overview](https://security.apple.com/documentation/private-cloud-compute/nontargetability#overview)
![](pcc-guide/routing-overview~dark@2x.png)
Our threat model for Private Cloud Compute includes an attacker with physical access to a compute node and a high level of sophistication — that is, an attacker who has the resources and expertise to subvert some of the hardware security properties of the system and potentially extract data that is being actively processed by a compute node.
We defend against this type of attack in two ways:
We supplement the built-in protections of Apple silicon with a hardened supply chain for PCC hardware, so that performing a hardware attack at scale is both prohibitively expensive and likely to be discovered.
We limit the impact of small-scale attacks by ensuring that they cannot be used to target the data of a specific user.
Private Cloud Compute hardware security starts at manufacturing, where we inventory and perform high-resolution imaging of the components of the PCC node before each server is sealed and its tamper switch is activated. When they arrive in the data center, we perform ~[extensive revalidation](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Certificate-ceremony-process)~ before the servers are allowed to be provisioned for PCC. The process involves multiple Apple teams that cross-check data from independent sources, and the process is further monitored by a third-party auditor not affiliated with Apple. At the end, a certificate is issued for ~[keys rooted in the Secure Enclave](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Cryptographic-identity)~for each PCC node. The user’s device does not send data to any PCC nodes if it cannot validate their certificates.
These processes broadly protect hardware from compromise. To guard against smaller, more sophisticated attacks that might otherwise avoid detection, Private Cloud Compute uses an approach called call target diffusion to ensure requests cannot be routed to specific nodes based on the user or their content.
*Target diffusion* starts with the request metadata, which leaves out any personally identifiable information about the source device or user, and includes only limited contextual data about the request, which is required to enable routing to the appropriate model. This metadata is the only part of the user’s request that is available to load balancers and other data-center components that run outside of the PCC trust boundary. The metadata also includes ~[a single-use credential](https://security.apple.com/documentation/private-cloud-compute/requestflow#Client-authentication)~, based on RSA Blind Signatures, to authorize valid requests without tying them to a specific user. Additionally, ~[PCC requests go through an OHTTP relay](https://security.apple.com/documentation/private-cloud-compute/requestflow#Network-transport)~ — operated by a third party — which hides the device’s source IP address before the request ever reaches the PCC infrastructure. This relay prevents an attacker from using an IP address to identify requests or associate requests with an individual. It also means that an attacker needs to compromise both the third-party relay and our load balancer to steer traffic based on the source IP address.
User devices encrypt requests ~[only for a subset of PCC nodes](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-selection)~, rather than the PCC service as a whole. When asked by a user device, the load balancer returns a subset of PCC nodes that are most likely to be ready to process the user’s inference request. However, as the load balancer has no identifying information about the user or device for which it’s choosing nodes, it cannot bias the set for targeted users. By limiting the PCC nodes that can decrypt each request in this way, we ensure that if a single node were to be compromised, it would not be able to decrypt more than a small portion of incoming requests. Finally, the selection of PCC nodes by the load balancer is statistically auditable to protect against a highly sophisticated attack where the attacker compromises a PCC node as well as obtains complete control of the PCC load balancer.
### Verifiable Transparency
Security researchers can verify the PCC privacy and security guarantees.
[Overview](https://security.apple.com/documentation/private-cloud-compute/verifiabletransparency#overview)
![](pcc-guide/release-transparency~dark@2x.png)
Allowing security researchers to verify the end-to-end security and privacy guarantees of Private Cloud Compute is a critical requirement for ongoing public trust in the system. Traditional cloud services do not make their full production software images available to researchers — and even if they did, there’s no general mechanism to allow researchers to verify that those software images match what’s actually running in the production environment. (Some specialized mechanisms exist, such as Intel SGX and AWS Nitro attestation.)
Private Cloud Compute takes the extraordinary step of making software images of **every build of PCC deployed into production publicly available for security research**. This transparency, too, is an enforceable guarantee: user devices are willing to send data only to PCC nodes that can ~[cryptographically attest](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cloud-Attestation)~ to running publicly listed software. We want to ensure that security and privacy researchers can inspect Private Cloud Compute software, verify its functionality, and help identify issues — just like they can with Apple devices.
Our commitment to verifiable transparency includes:
Publishing the measurements of all code running on PCC in an ~[append-only and cryptographically tamper-proof transparency log](https://security.apple.com/documentation/private-cloud-compute/releasetransparency)~.
Making the log and associated binary software images publicly available for inspection and validation by privacy and security experts.
Publishing and maintaining an official set of tools for researchers analyzing PCC node software.
Rewarding important research findings through the ~[Apple Security Bounty](https://security.apple.com/bounty/)~ program.
Every production Private Cloud Compute software image is ~[published for independent binary inspection](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Binary-transparency)~ — including the OS, applications, and all relevant executables, all of which researchers can verify against the measurements in the transparency log. Software is published within 90 days of inclusion in the log, or after relevant software updates are available, whichever is sooner. Once a release has been signed into the log, it cannot be removed without detection, much like the log-backed map data structure used by the Key Transparency mechanism for ~[iMessage Contact Key Verification](https://security.apple.com/blog/imessage-contact-key-verification/)~.
As we mentioned, user devices ensure that they’re communicating only with PCC nodes running ~[authorized and verifiable software images](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-validation)~. Specifically, the user’s device wraps its request payload key only to the public keys of those PCC nodes that have attested measurements matching a software release in the public transparency log. These attestations are rooted in the immutable hardware features of Apple silicon: ~[cryptographic identities](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Cryptographic-identity)~, ~[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Secure-and-measured-boot)~, and ~[hardware-based attestation](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Hardware-attestation)~. Because these features are implemented in hardware and fixed in the silicon, their behavior cannot change after manufacturing.
Making Private Cloud Compute software logged and inspectable in this way is a strong demonstration of our commitment to enable independent research on the platform. But we want to ensure researchers can rapidly get up to speed, verify our PCC privacy claims, and look for security and privacy issues, so we’re going a step further and releasing the ~[PCC Virtual Research Environment](https://security.apple.com/documentation/private-cloud-compute/virtualresearchenvironment)~: a set of tools and images that simulate a PCC node on a Mac with Apple silicon, and that can boot a version of PCC software minimally modified for successful virtualization.

### Hardware Root of Trust
Custom-built server hardware ensures security properties are immutable.
[Overview](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#overview)
Private Cloud Compute takes the extraordinary step of allowing security researchers to verify its end-to-end security and privacy guarantees. This **verifiable** **transparency** requirement is technically enforceable — user devices will send data to PCC nodes only if they are running software that Apple has publicly logged for inspection by security researchers, and researchers can download and inspect all software running on production PCC nodes to validate our claims.
When a user’s device sends an inference request to Private Cloud Compute, the request is sent end-to-end encrypted to the specific PCC nodes needed for the request. The PCC nodes share a public key and an attestation — cryptographic proof of key ownership and measurements of the software running on the PCC node — with the user’s device, and the user’s device compares these measurements against a public, append-only ledger of PCC software releases.
To better explain why a user’s device can trust the attestation, we start by detailing Private Cloud Compute’s root of trust — Apple silicon — an immutable component of the system that serves as the basis for these software attestations.
[Apple silicon root of trust](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Apple-silicon-root-of-trust)
Apple silicon has three key, immutable features that are critical to verifiable transparency:
**Hardware-backed cryptographic identity:** Cryptographic keys are securely generated during manufacturing and fused into the silicon. These keys are accessible only to the Secure Enclave Processor (SEP) to perform cryptographic operations that prove its identity. They remain protected by the hardware and are not exportable.
**Secure and Measured Boot:** ~[Secure Boot](https://support.apple.com/guide/security/boot-process-for-iphone-and-ipad-devices-secb3000f149/1/web/1)~ technology measures and validates all code running on the device. The Boot ROM, the start of the Secure Boot process, is laid onto the silicon during fabrication and is therefore immutable.
**Hardware-based attestation:** The Secure Enclave can sign measurements of the software using its hardware-backed identity.
These three features enable Apple silicon to support the remote attestations that facilitate verifiable transparency. These features are immutable — even Apple cannot change them after manufacturing — and supported by Apple’s robust supply-chain integrity and code-audit processes that include multiple rounds of both internal and external verification.
When combined, these features provide reliable information about the software running on PCC nodes.
[Cryptographic identity](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Cryptographic-identity)
The ~[Secure Enclave](https://support.apple.com/guide/security/secure-enclave-sec59b0b31ff/web)~ is a special coprocessor on Apple’s System-on-Chip (SoC). It’s built on a set of related hardware security features, including a true random-number generator, a Public-Key Accelerator (PKA), and a dedicated Advanced Encryption Standard engine. The SEP integrates these blocks to provide key-management primitives that remain secure even if the rest of the system is compromised.
The Secure Enclave contains special hardware blocks to enable the use of hardware-bound keys. During manufacturing, the Secure Enclave executes a special process within its own trust boundary that uses the dedicated true random-number generator to fuse a Unique ID (UID) into the silicon. The PKA uses this UID as an input to its cryptographic key-generation block, ensuring that all keys it generates are entangled with the UID and bound to the given Secure Enclave. The UID and the private pairing of all PKA keys are never exposed to any software, even software running on the SEP itself. The SEP can access them only indirectly through limited functionality exposed by the PKA.
The Secure Enclave can use the UID to derive ephemeral keys by mixing it with random seeds or to derive long-lived keys by mixing it with fixed seeds. These long-lived keys form the basis of a durable cryptographic identity that can be used to identify a particular SEP, and therefore a particular SoC. For Private Cloud Compute, we created a new Data Center Identity Key (DCIK), which is generated within the PKA of the Secure Enclave using a fixed seed, and the public pairing of this identity key is recorded in Apple’s device database during manufacturing.
[Secure and measured boot](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Secure-and-measured-boot)
The Application Processor (AP) block is the powerhouse that provides the primary compute for the SoC. The AP’s root of trust begins with Boot ROM, the boot code that’s laid onto the silicon during SoC fabrication. This code is part of the SoC silicon and is immutable. Boot ROM handles initial bootstrapping of the SoC, after which it validates the node’s Image4 boot manifest, the APTicket. Image4 is Apple’s ASN.1-based, secure boot specification, which we use to manage the authorized lifetime of code via our Trusted Signing Service (TSS). The APTicket contains signed measurements of the iBoot (system boot loader) image and each firmware image for the system.
After validating the manifest, Boot ROM measures the iBoot image and ensures that it matches the manifest. Before passing control to iBoot, Boot ROM locks the digest of the manifest into the write-once system register SEAL_DATA_A. Boot ROM is immutable, which means its behavior of enforcing secure boot and locking the manifest in SEAL_DATA_A cannot be changed after manufacturing, even by Apple.
After iBoot completes setup, it loads and validates additional boot images described in the APTicket.
The Secure Enclave’s trust boundary does not extend to the rest of the SoC, so the SEP implements its own secure boot. Upon reset, the SEP begins executing from the Secure Enclave Boot ROM (SEPROM). SEPROM is immutable, like Boot ROM on the AP, and is laid down on the silicon during SoC fabrication. SEPROM forms the hardware root of trust on the SEP and bootstraps sepOS, the firmware image that runs on the SEP. Much like how Boot ROM locks down SEAL_DATA_A before handing off code execution to iBoot, the SEPROM locks down a register known as SEAL_DATA with the digest of the sepOS image.
[Hardware attestation](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust#Hardware-attestation)
Hardware attestation builds upon measured boot and hardware-rooted cryptographic identities. The PKA can generate attestations that attest key residency of PKA-resident keys to security-critical system states such as SEAL_DATA and SEAL_DATA_A. This attestation works by hashing the public key of the attested key with the content of these hardware registers, and then signing the resulting hash with a long-lived key, such as the DCIK. This step cryptographically ties a given key pair to the measurements booted by Boot ROM. Because the PKA behavior is implemented entirely within hardware, including reading the values of the SEAL_DATA and SEAL_DATA_A registers, this behavior is also immutable and cannot be changed after manufacturing.
### Hardware Integrity
Hardware used for PCC is subject to rigorous security processes.
[Overview](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#overview)
Attestation allows a user’s device to communicate with a PCC node based on its strong cryptographic identity. Establishing trust in that identity requires knowing whether a specific Data Center Identity Key (DCIK) belongs to a trustworthy PCC node. To enable this, the Data Center Attestation Certificate Authority (DCA CA) issues a certificate to each PCC node that identifies it as authentic PCC hardware and certifies that its hardware security features meet PCC security requirements.
This certification is a representation that:
Each certificate is issued to the public key that corresponds to a private key resident in the Secure Enclave of an authentic Apple silicon SoC.
The hardware environment of the SoC, including the other components in the chassis, is not tampered with or modified.
By ensuring that the DCA CA issues certificates only to verified authentic hardware that exactly matches expected manufacturing records, we prevent anyone — including a malicious insider — from injecting non-genuine hardware that has untrustworthy attestations into the PCC fleet.
When designing the provisioning process to ensure certificate integrity, we took inspiration from other multi-party ceremony processes, such as ~[WebTrust](https://www.cpacanada.ca/business-and-accounting-resources/audit-and-assurance/overview-of-webtrust-services/principles-and-criteria)~’s CA Key Generation controls (or ~[Cloud Key Vault](https://youtu.be/BLGFriOKz6U?si=LBanwEVoY5m4jy6y&t=1946)~), and applied these techniques to protect the ongoing process rather than just the generation of initial keys. This design ensures that it is exceptionally difficult to attempt to maliciously induce certificate misissuance, and that any such attempt requires wide-ranging and difficult efforts that leave a clear audit trail and are overwhelmingly likely to be detected.
[Hardware design](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Hardware-design)
The attack surface of the hardware is an important consideration. We define the trust boundary as the PCC node and consider all interfaces and inputs untrusted. These interfaces to other hardware components in the server chassis represent an attack surface that someone might attempt to use to circumvent our Secure Boot or attestation flows. Because we need many of these interfaces to manage the hardware and cannot remove them entirely, our threat model for such attacks focuses on detecting external manipulation.
The manufacturing process starts with the assembly of multiple PCC nodes into a server chassis alongside an Apple silicon baseboard management controller (BMC). The chassis design limits the physical attack surface of the PCC nodes and enables tampering detection. The BMC has USB connectivity to each of the PCC nodes and uses this connectivity to install software and manage system state. The chassis maintains a built-in tamper switch that resets the power supply for the entire chassis in the event someone opens the lid. Finally, we attest and seal all components of the chassis, including the BMC and system-management microcontrollers, into a manifest that we verify during provisioning and periodically thereafter.
[Hardware lifecycle](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Hardware-lifecycle)
Protecting the hardware lifecycle starts during manufacturing. Using the cryptographic identity of each Apple silicon SoC to track its lifecycle from production to the finished server chassis produces reliable documentation of the hardware supply chain for our certificate issuance process.
During assembly, each printed circuit board (PCB) is automatically scanned at high resolution, both optically and by X-ray, prior to the addition of any thermal modules. The images are permanently recorded and run through an anomaly detection mechanism that analyzes each PCB and compares it to known reference images. This record provides a point of reference for comparison — for example, following field failure of a part — while also providing assurance that every PCB matches Apple reference designs for PCC. The automated imaging is controlled by an Apple security team and is on a fully separate network from the rest of the factory-floor systems.
During the assembly of a PCC chassis, we:
Create a signed manifest of the cryptographic identity embedded in each SoC and microcontroller.
Activate the built-in tamper switch. The chassis tamper switch is attached to a battery-backed, real-time clock that stores an anti-replay value in SRAM, which is rotated in the event that tampering activity activates the switch.
Record the sealed identities into the Apple Component Attestation Authority (CAA), the same system we use to verify the integrity of parts in user devices.
Record these identities in the manufacturing asset database and the data center asset database. The use of multiple systems helps ensure that the compromise of a single credential doesn’t enable an attacker to bypass our process.
For any shipment of PCC hardware, we work with our logistics partners to ensure a strong chain of custody from factory to integration centers. Each shipment is actively monitored, with both Apple employees and shipping partners monitoring the route that the package takes, along with expected delivery dates and times. All shipments are in secure, sealed packaging and photographed upon arrival.
Integration center staff assemble PCC node hardware into racks. During assembly, the integration-center engineers record the layout of each rack in the Apple data center asset database. Apple then re-verifies the expected systems by using this database when a data center deploys a rack. Once deployed, all software on the PCC chassis, including microcontroller firmware, is updated to a current production PCC release prior to performing the certificate issuance process.
Apple actively monitors the status of the tamper switch for each PCC chassis during regular operations to detect any unexpected event where the chassis is opened. If this monitoring detects that the tamper anti-replay value on a production chassis has been rotated, indicating an activated tamper switch, the chassis is taken out of service until the integrity of the system is reaffirmed. To help ensure that hardware remains in the same secure condition as when it left the factory, we image and analyze a statistically significant sample of PCC nodes using the same imaging process used when they were manufactured.
[Certificate ceremony process](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Certificate-ceremony-process)
Before PCC nodes can handle user requests, a hardware audit ensures that they’re authentic, untampered Apple silicon, and that they meet our integrity standards. The audit implements multiple controls to validate hardware and software integrity for each PCC node and confirm that each node is deployed in the data center in the same state in which it left the factory. These controls are performed by a quorum of employees from three Apple organizations and witnessed by a third-party independent auditor.
These controls verify that:
The inventory of components and their cryptographic identities match both the data center asset database and the manufacturing asset database, by querying the BMC on each PCC chassis.
The data center asset database provides change logs for the entire history of a chassis; the database drives data center operations and is updated immediately following changes, such as when a chassis is installed into a rack, or racks are moved to a new location.
The manufacturing asset database provides a record of each chassis in the factory prior to shipping. This record provides a fixed-in-time comparison point, to ensure that the contents of each chassis show no changes since shipment.
Repair records of each chassis that was removed from service for maintenance are checked to ensure the integrity of the replacement components.
The physical location of each chassis matches the data in our data center asset database. The third-party auditor randomly selects a subset of nodes for which the location is manually confirmed, to validate the integrity of the data center asset database.
The tamper switch in each chassis has not been activated, and all the components in each chassis are attested to by the Component Attestation Authority following a challenge-response. This attestation provides cryptographic assurance in support of the integrity of each chassis.
The software release deployed to each PCC node going through the ceremony has been published to the PCC transparency log, which confirms that operations run by the ceremony process on the PCC nodes are using a known release of software and prevents anyone from subverting the ceremony process without detection.
Each SoC is a valid, physical Apple silicon part with the correct specifications. We issue ~[Basic Attestation Authority certificates to SEP-backed keys](https://support.apple.com/guide/deployment/managed-device-attestation-dep28afbde6a/web)~ and verify that the certificate attributes indicate that the SEP meets PCC security requirements.
After successful exercise of these controls, the ceremony team issues DCIK certificates from the Data Center Attestation Certificate Authority (DCA CA). The security of the DCA CA and its process is critical, because the ability to issue a DCIK certificate might enable an attacker to impersonate legitimate PCC nodes. We ensure its security by using an offline certificate authority backed by Hardware Security Modules (HSMs) that are designed to the latest FIPS-140-3 standard, and we require multi-party approval with hardware authentication tokens.
The HSMs that the DCA CA uses to protect its private key produce a signed, immutable log for all key operations they perform, which is verified at the start of each ceremony by comparing the log from the end of the previous ceremony to the log at the start of the next. This ensures that any hypothetical certificate misissuance outside of sanctioned ceremonies is detected. If such a case were to be detected, the new ceremony would be terminated, and we’d publicly disclose this event as a critical security incident.
Between ceremonies, the ceremony team places the HSM hardware in tamper-evident bags and stores the bags in a safe that requires multi-party control to unlock. Each quorum member also stores their HSM authentication tokens in tamper-evident bags in their representative organizations’ safes. This approach means each ceremony requires items from four different safes: the multi-party safe that stores the HSM hardware and three organization safes that store admin cards.
The external third-party auditor follows SOC2 and SOC3 standards and is contractually required to be independent and impartial to this process. Apple will periodically publish the SOC3 report from the third-party auditor covering all the ceremonies that took place within the timeframe covered by the report.
Because certification is critical to protect the PCC hardware root of trust, we engaged a third-party security research firm to perform a detailed review of the ceremony process. Apple will publish the third-party firm’s report after the engagement is completed.
### Software Foundations
PCC nodes run a purpose-built operating system designed for protecting user data.
[Overview](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#overview)
The security and privacy properties of the PCC node must be verifiable, so we designed the PCC node’s custom operating system using a minimized and hardened subset of iOS with the following goals:
The behavior of the system can be well understood by a security researcher through analysis of the software.
The entire set of software that can run on the system is measurable and described by the attestation.
Software is immutable at runtime and can change only during a reboot, which invalidates previously attested keys, and thus previous attestations.
We use hardware-based attestation to verify the boot firmware. But for user devices to verify the transparency guarantees, we also follow the hardware measurements with a chain of trust that covers all software within the trust boundary of a PCC node.
To allow comprehensive analysis of the software running on PCC nodes, we disable or remove mechanisms to execute code dynamically, including:
System shells (e.g. zsh)
Interpreters (e.g. JavaScriptCore)
Debuggers (e.g. debugserver)
Just-In-Time (JIT) compiler functionality
PCC strives for the smallest possible attack and audit surface, while still enabling our desired workloads. PCC uses a small subset of the total code present on other iOS devices. The node’s operating system includes only a minimal set of boot firmware, SEP applications, and kernel extensions — and it excludes drivers and firmware for unused hardware components whenever possible.
The system includes the same GPU and ANE functionality present in iOS, including the firmware and Metal stack. Large Language Model (LLM) functionality and application logic are packaged and loaded using ~[cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~: archives of artifacts that represent a fully signed and integrity-verified standalone software distribution package.
The nodes boot using our ~[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)~ implementation, which loads the system to user space. Within user space, our initialization task, ~[darwin-init](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#darwin-init)~, sets up the node based on the configuration it obtains from the BMC, such as the set of cryptexes to load. Once it loads all Cryptexes, darwin-init initiates entry into ~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~, after which the node becomes available for serving external requests.
[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)
As described in ~[Hardware Root of Trust](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust)~, Apple silicon’s ~[Secure Boot](https://support.apple.com/guide/security/boot-process-for-iphone-and-ipad-devices-secb3000f149/1/web/1)~process starts with the Boot ROM and SEPROM. These immutable components of the SoC start the boot process by validating the Image4 boot manifest, called the APTicket, then verifying the measurements of the iBoot and SEP firmware against this manifest. If the verification is successful, the measurements of the manifest are then locked in the SEAL_DATA_A and SEAL_DATA registers before starting execution of the iBoot and sepOS, respectively.
After validating the APTicket and iBoot images, the Boot ROM continues the boot flow by handing off execution to iBoot. iBoot extends the boot chain and verifies the system’s firmware against the APTicket, including the Secure Page Table Monitor (SPTM), the Trusted Execution Monitor (TXM), and the Kernel Cache. Just like with iOS, iBoot then hands off execution to the SPTM, which bootstraps the system’s memory management unit, initializes TXM, and then hands off control flow to the kernel. The kernel initializes the rest of the system and boots to user space, where ~[Code Signing](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Code-Signing)~ policies extend Secure Boot into user space.
The SEP has its own boot process rooted in the SEPROM. An early boot task in user-space on the Application Processor (AP) initiates the flow for issuing a boot command to the SEP. Once SEPROM receives this command, it copies the sepOS firmware into protected memory and independently verifies its signature. Upon success, the SEPROM begins executing sepOS, which in turn begins loading SEP applications.
Both the AP and the SEP use the Image4 format for Secure Boot. The Image4 manifest format contains constraints, such as a device’s hardware identifier, which cryptographically bind the Image4 manifest to an SoC, a technique known as ~[personalization](https://support.apple.com/guide/security/secure-software-updates-secf683e0b36/web)~. This binding means that manifests are not transportable among devices. The binding also includes values that cannot be determined without the direct participation of the SoC, such as rotating anti-reply values. A list of Image4 tags and constraints is included in ~[Appendix: Secure Boot Tags](https://security.apple.com/documentation/private-cloud-compute/appendix_secureboot)~.
[Software Sealed Registers](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Software-Sealed-Registers)
To capture measurements that exist outside of SEAL_DATA and SEAL_DATA_A, the SEP provides a service to the AP called Software Sealed Registers (SSRs) that allows measurements to be ratcheted into the SEP. This service is similar to the function of a TPM’s Platform Configuration Register. Attestations generated by the SEP capture the contents of these SSRs. The APTicket captures the baseline software loaded on the AP, and the SSRs capture tunable configuration data and additional software packages that the PCC node loads after boot.
An SSR starts out empty, and the AP can update it to include data digests. For each update, the SEP takes the current value of the SSR and concatenates it with the incoming update to construct a new value that it stores back into the SSR. An update operation is a ratcheting step because it cannot be rolled back. When the system finishes initialization, the AP can ask the SEP to lock an SSR so it cannot be updated further, and this lock state is included in the attestation. In addition, the SEP entangles the SSR state with encryption keys used to securely communicate with PCC nodes, which causes the keys to become inaccessible if the SSR’s contents change.
The following example illustrates the functioning of an SSR:
SSR: Empty
|
| Operation: Update(SHA-384('hello')) <-- ✅
| Value: 59e17487...e828684f
|
| Operation: Update(SHA-384('world')) <-- ✅
| Value: f715f491...c96a1182
|
| Operation: Lock <-- ✅
| Value: f715f491...c96a1182
|
| Operation: Update(SHA-384('invalid')) <-- ❌
| Value: f715f491...c96a1182


Where:
SHA-384('hello'): 59e17487...e828684f
SHA-384('world'): a4d102bb...7d3ea185
SHA-384(SHA-384('hello') || SHA-384('world')): f715f491...c96a1182
There are two Software Sealed Registers used by PCC nodes:
**Cryptex Manifest Register**: Contains the digests of all the Image4 manifests from ~[cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~ activated on the AP.
**Configuration Seal Register**: Contains a digest of a subset of the configuration file that ~[darwin-init](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#darwin-init)~ uses to set up the node.
[Code Signing](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Code-Signing)
Boot ROM and iBoot ensure that the boot process loads only the measured and attested firmware and kernel cache. Private Cloud Compute attestations must cover all software that might run on the device, so the complete set of user-space code is described by a set of ~[trust caches](https://support.apple.com/guide/security/trust-caches-sec7d38fbf97/1/web/1)~, both as part of the APTicket and as components of cryptexes.
To enforce this behavior, the code-execution policy on a PCC node is managed by a separate monitor layer, the ~[Trusted Execution Monitor](https://support.apple.com/guide/security/operating-system-integrity-sec8b776536b/web#secd022396fb)~(TXM), rather than the kernel. This separation helps ensure that a kernel compromise is not sufficient to execute arbitrary code on the node — an attacker would also need to bypass the TXM.
The TXM enforces several restrictive policies on PCC nodes to ensure that only known code can execute:
All code must be covered by a trust cache.
JIT mappings cannot be created.
~[Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)~ cannot be enabled.
Debugging workflows are not supported.
PCC has an explicit goal that any code that runs on the node must be attested to. The base operating system contains services and daemons that set up the node. The digest of each binary on the base operating system is contained within the static trust cache, which is authorized by the APTicket and loaded by iBoot. Additional software outside the base operating system can be delivered to the system only in the form of ~[cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~, which contain their own Image4 manifest and trust cache. This design enables the SEP’s attestation to capture all code contained within a cryptex before the code can run. For details on the trust cache format, see ~[Appendix: Trust Cache Format](https://security.apple.com/documentation/private-cloud-compute/appendix_trustcache)~.
The Cryptex Manifest Register is a ~[Software Sealed Register](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Software-Sealed-Registers)~ that contains ratcheted digests of the Image4 manifests for all cryptexes that the AP loads. Unlike other SSRs, the AP cannot directly update this register. Instead, its contents are controlled by the SEP and are managed as follows:
Before a cryptex is activated by cryptexd on the AP, cryptexdpresents its Image4 manifest to the SEP.
The SEP independently validates the manifest and, if successful, updates the Cryptex Manifest Register with the manifest’s digest.
The SEP also writes the digest to a special memory page that’s shared with TXM and not writable by any other component, including the AP kernel.
TXM then enforces that only trust caches included in this page may be used to load executable code, ensuring that all trust caches are reflected in an attestation.
TXM’s trust boundary doesn’t include the AP kernel, so the system has a special SEP-TXM page to facilitate direct communication between these components. We designed this direct channel to ensure that new code on the system cannot be loaded without first being recorded by the SEP for inclusion in attestations. Even with a kernel compromise, an attacker must also compromise either the SEP or TXM.
[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)
The PCC node uses a new feature called Restricted Execution Mode (REM) to lock out functionality that’s required only during the system’s initial setup. Entering REM is enforced by TXM as a one-way transition, after which TXM refuses to load additional trust caches and imposes new constraints on code execution. The state of REM is communicated from TXM to the SEP using the SEP-TXM page, and is included by the SEP in all attestations it generates.
In REM-enabled trust caches, each trust cache entry includes an 8-bit flag field. Two of those bits represent REM permissions and indicate whether code is permitted to run if REM is supported, permitted before or after entering REM, or permitted regardless of REM. If the trust cache being evaluated by TXM doesn’t contain a REM policy (for example, because it’s a previous version of the format that doesn’t support REM policy), TXM assumes that both bits are zero.
| **Restricted Execution Mode Policy** | **High Bit** | **Low Bit** |
|---|---|---|
| **None**: Never permitted if REM is supported | 0 | 0 |
| **Before**: Only permitted prior to REM | 0 | 1 |
| **After**: Only permitted after REM | 1 | 0 |
| **Both**: Permitted regardless of REM | 1 | 1 |
A PCC node cannot transition into REM if there is any *before* code resident in memory. If a daemon with the *before* policy has been launched by launchd, TXM enforces that it must be killed, even if it’s completely idle and not actively running code. This is designed to ensure that unnecessary code has been unloaded prior to processing any user data, thereby reducing the attack surface of the system.
Additionally, TXM denies entering REM if the ~[Cryptex Manifest Register](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Software-Sealed-Registers)~ is unlocked. While the contents of this register are controlled by the SEP, the AP still must ask the SEP to lock it. The lock state of this register is communicated from the SEP to TXM using the SEP-TXM page.
[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)
PCC nodes operate in a new Ephemeral Data Mode, which has two functions:
**Per-boot Data volume**: Ensures any data written to the system doesn’t persist to the next boot of the system. While running, software uses the data volume to store temporary computational data as it runs. All that data must be erased by the system between boots to prevent different software with different security properties from accessing that data.
**Anti-persistence**: Limits the impact of a compromised compute node to a single boot session to prevent an attacker from remaining resident on the node, or re-exploiting the node for an extended period of time.
[Per-boot Data volume](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Per-boot-Data-volume)
Mutable data on a PCC node is intended to be stored on a dedicated data volume, separate from the immutable ~[Signed System Volume](https://support.apple.com/guide/security/signed-system-volume-security-secd698747c9/web)~that contains the operating system. The dedicated data volume is encrypted with a storage-key hierarchy managed by the SEP. iOS features, like ~[Erase All Content & Settings](https://support.apple.com/guide/personal-safety/how-to-erase-all-content-and-settings-ips4603248a8/web)~, where user data can be quickly and reliably erased without modifying the system volume, use this same data-volume separation design.
With Ephemeral Data Mode enabled, the SEP randomizes this storage-key hierarchy at every boot. This cryptographically guarantees that no data-volume state written in a session can be read by any subsequent boot session.
On subsequent boot sessions, the mobile_obliterator boot task discards the previous encrypted data volume and reconstructs a clean volume from known-safe data, prior to loading other daemons.
[Anti-persistence](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Anti-persistence)
Some storage regions are not covered by the SEP’s key-hierarchy randomization nor validated during the boot process by ~[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)~. This includes persistent data stores such as NVRAM and the Preboot volume. These data stores have existing protections, designed to limit which processes can read and write data, that prevent anyone from accidentally or maliciously storing user data in them.
Our threat model assumes full node compromise where those protections are defeated. Accordingly, we also reset these data stores to a clean state on each system boot, so crafted values cannot be used by an attacker to influence subsequent boot sessions. These protections are implemented across several system components, including iBoot, MobileObliteration, and ~[darwin-init](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#darwin-init)~.
### Software Foundations
PCC nodes run a purpose-built operating system designed for protecting user data.
[Overview](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#overview)
The security and privacy properties of the PCC node must be verifiable, so we designed the PCC node’s custom operating system using a minimized and hardened subset of iOS with the following goals:
The behavior of the system can be well understood by a security researcher through analysis of the software.
The entire set of software that can run on the system is measurable and described by the attestation.
Software is immutable at runtime and can change only during a reboot, which invalidates previously attested keys, and thus previous attestations.
We use hardware-based attestation to verify the boot firmware. But for user devices to verify the transparency guarantees, we also follow the hardware measurements with a chain of trust that covers all software within the trust boundary of a PCC node.
To allow comprehensive analysis of the software running on PCC nodes, we disable or remove mechanisms to execute code dynamically, including:
System shells (e.g. zsh)
Interpreters (e.g. JavaScriptCore)
Debuggers (e.g. debugserver)
Just-In-Time (JIT) compiler functionality
PCC strives for the smallest possible attack and audit surface, while still enabling our desired workloads. PCC uses a small subset of the total code present on other iOS devices. The node’s operating system includes only a minimal set of boot firmware, SEP applications, and kernel extensions — and it excludes drivers and firmware for unused hardware components whenever possible.
The system includes the same GPU and ANE functionality present in iOS, including the firmware and Metal stack. Large Language Model (LLM) functionality and application logic are packaged and loaded using ~[cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~: archives of artifacts that represent a fully signed and integrity-verified standalone software distribution package.
The nodes boot using our ~[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)~ implementation, which loads the system to user space. Within user space, our initialization task, ~[darwin-init](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#darwin-init)~, sets up the node based on the configuration it obtains from the BMC, such as the set of cryptexes to load. Once it loads all Cryptexes, darwin-init initiates entry into ~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~, after which the node becomes available for serving external requests.
[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)
As described in ~[Hardware Root of Trust](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust)~, Apple silicon’s ~[Secure Boot](https://support.apple.com/guide/security/boot-process-for-iphone-and-ipad-devices-secb3000f149/1/web/1)~process starts with the Boot ROM and SEPROM. These immutable components of the SoC start the boot process by validating the Image4 boot manifest, called the APTicket, then verifying the measurements of the iBoot and SEP firmware against this manifest. If the verification is successful, the measurements of the manifest are then locked in the SEAL_DATA_A and SEAL_DATA registers before starting execution of the iBoot and sepOS, respectively.
After validating the APTicket and iBoot images, the Boot ROM continues the boot flow by handing off execution to iBoot. iBoot extends the boot chain and verifies the system’s firmware against the APTicket, including the Secure Page Table Monitor (SPTM), the Trusted Execution Monitor (TXM), and the Kernel Cache. Just like with iOS, iBoot then hands off execution to the SPTM, which bootstraps the system’s memory management unit, initializes TXM, and then hands off control flow to the kernel. The kernel initializes the rest of the system and boots to user space, where ~[Code Signing](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Code-Signing)~ policies extend Secure Boot into user space.
The SEP has its own boot process rooted in the SEPROM. An early boot task in user-space on the Application Processor (AP) initiates the flow for issuing a boot command to the SEP. Once SEPROM receives this command, it copies the sepOS firmware into protected memory and independently verifies its signature. Upon success, the SEPROM begins executing sepOS, which in turn begins loading SEP applications.
Both the AP and the SEP use the Image4 format for Secure Boot. The Image4 manifest format contains constraints, such as a device’s hardware identifier, which cryptographically bind the Image4 manifest to an SoC, a technique known as ~[personalization](https://support.apple.com/guide/security/secure-software-updates-secf683e0b36/web)~. This binding means that manifests are not transportable among devices. The binding also includes values that cannot be determined without the direct participation of the SoC, such as rotating anti-reply values. A list of Image4 tags and constraints is included in ~[Appendix: Secure Boot Tags](https://security.apple.com/documentation/private-cloud-compute/appendix_secureboot)~.
[Software Sealed Registers](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Software-Sealed-Registers)
To capture measurements that exist outside of SEAL_DATA and SEAL_DATA_A, the SEP provides a service to the AP called Software Sealed Registers (SSRs) that allows measurements to be ratcheted into the SEP. This service is similar to the function of a TPM’s Platform Configuration Register. Attestations generated by the SEP capture the contents of these SSRs. The APTicket captures the baseline software loaded on the AP, and the SSRs capture tunable configuration data and additional software packages that the PCC node loads after boot.
An SSR starts out empty, and the AP can update it to include data digests. For each update, the SEP takes the current value of the SSR and concatenates it with the incoming update to construct a new value that it stores back into the SSR. An update operation is a ratcheting step because it cannot be rolled back. When the system finishes initialization, the AP can ask the SEP to lock an SSR so it cannot be updated further, and this lock state is included in the attestation. In addition, the SEP entangles the SSR state with encryption keys used to securely communicate with PCC nodes, which causes the keys to become inaccessible if the SSR’s contents change.
The following example illustrates the functioning of an SSR:
SSR: Empty
|
| Operation: Update(SHA-384('hello')) <-- ✅
| Value: 59e17487...e828684f
|
| Operation: Update(SHA-384('world')) <-- ✅
| Value: f715f491...c96a1182
|
| Operation: Lock <-- ✅
| Value: f715f491...c96a1182
|
| Operation: Update(SHA-384('invalid')) <-- ❌
| Value: f715f491...c96a1182


Where:
SHA-384('hello'): 59e17487...e828684f
SHA-384('world'): a4d102bb...7d3ea185
SHA-384(SHA-384('hello') || SHA-384('world')): f715f491...c96a1182
There are two Software Sealed Registers used by PCC nodes:
**Cryptex Manifest Register**: Contains the digests of all the Image4 manifests from ~[cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~ activated on the AP.
**Configuration Seal Register**: Contains a digest of a subset of the configuration file that ~[darwin-init](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#darwin-init)~ uses to set up the node.
[Code Signing](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Code-Signing)
Boot ROM and iBoot ensure that the boot process loads only the measured and attested firmware and kernel cache. Private Cloud Compute attestations must cover all software that might run on the device, so the complete set of user-space code is described by a set of ~[trust caches](https://support.apple.com/guide/security/trust-caches-sec7d38fbf97/1/web/1)~, both as part of the APTicket and as components of cryptexes.
To enforce this behavior, the code-execution policy on a PCC node is managed by a separate monitor layer, the ~[Trusted Execution Monitor](https://support.apple.com/guide/security/operating-system-integrity-sec8b776536b/web#secd022396fb)~(TXM), rather than the kernel. This separation helps ensure that a kernel compromise is not sufficient to execute arbitrary code on the node — an attacker would also need to bypass the TXM.
The TXM enforces several restrictive policies on PCC nodes to ensure that only known code can execute:
All code must be covered by a trust cache.
JIT mappings cannot be created.
~[Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)~ cannot be enabled.
Debugging workflows are not supported.
PCC has an explicit goal that any code that runs on the node must be attested to. The base operating system contains services and daemons that set up the node. The digest of each binary on the base operating system is contained within the static trust cache, which is authorized by the APTicket and loaded by iBoot. Additional software outside the base operating system can be delivered to the system only in the form of ~[cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~, which contain their own Image4 manifest and trust cache. This design enables the SEP’s attestation to capture all code contained within a cryptex before the code can run. For details on the trust cache format, see ~[Appendix: Trust Cache Format](https://security.apple.com/documentation/private-cloud-compute/appendix_trustcache)~.
The Cryptex Manifest Register is a ~[Software Sealed Register](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Software-Sealed-Registers)~ that contains ratcheted digests of the Image4 manifests for all cryptexes that the AP loads. Unlike other SSRs, the AP cannot directly update this register. Instead, its contents are controlled by the SEP and are managed as follows:
Before a cryptex is activated by cryptexd on the AP, cryptexdpresents its Image4 manifest to the SEP.
The SEP independently validates the manifest and, if successful, updates the Cryptex Manifest Register with the manifest’s digest.
The SEP also writes the digest to a special memory page that’s shared with TXM and not writable by any other component, including the AP kernel.
TXM then enforces that only trust caches included in this page may be used to load executable code, ensuring that all trust caches are reflected in an attestation.
TXM’s trust boundary doesn’t include the AP kernel, so the system has a special SEP-TXM page to facilitate direct communication between these components. We designed this direct channel to ensure that new code on the system cannot be loaded without first being recorded by the SEP for inclusion in attestations. Even with a kernel compromise, an attacker must also compromise either the SEP or TXM.
[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)
The PCC node uses a new feature called Restricted Execution Mode (REM) to lock out functionality that’s required only during the system’s initial setup. Entering REM is enforced by TXM as a one-way transition, after which TXM refuses to load additional trust caches and imposes new constraints on code execution. The state of REM is communicated from TXM to the SEP using the SEP-TXM page, and is included by the SEP in all attestations it generates.
In REM-enabled trust caches, each trust cache entry includes an 8-bit flag field. Two of those bits represent REM permissions and indicate whether code is permitted to run if REM is supported, permitted before or after entering REM, or permitted regardless of REM. If the trust cache being evaluated by TXM doesn’t contain a REM policy (for example, because it’s a previous version of the format that doesn’t support REM policy), TXM assumes that both bits are zero.
| **Restricted Execution Mode Policy** | **High Bit** | **Low Bit** |
|---|---|---|
| **None**: Never permitted if REM is supported | 0 | 0 |
| **Before**: Only permitted prior to REM | 0 | 1 |
| **After**: Only permitted after REM | 1 | 0 |
| **Both**: Permitted regardless of REM | 1 | 1 |
A PCC node cannot transition into REM if there is any *before* code resident in memory. If a daemon with the *before* policy has been launched by launchd, TXM enforces that it must be killed, even if it’s completely idle and not actively running code. This is designed to ensure that unnecessary code has been unloaded prior to processing any user data, thereby reducing the attack surface of the system.
Additionally, TXM denies entering REM if the ~[Cryptex Manifest Register](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Software-Sealed-Registers)~ is unlocked. While the contents of this register are controlled by the SEP, the AP still must ask the SEP to lock it. The lock state of this register is communicated from the SEP to TXM using the SEP-TXM page.
[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)
PCC nodes operate in a new Ephemeral Data Mode, which has two functions:
**Per-boot Data volume**: Ensures any data written to the system doesn’t persist to the next boot of the system. While running, software uses the data volume to store temporary computational data as it runs. All that data must be erased by the system between boots to prevent different software with different security properties from accessing that data.
**Anti-persistence**: Limits the impact of a compromised compute node to a single boot session to prevent an attacker from remaining resident on the node, or re-exploiting the node for an extended period of time.
[Per-boot Data volume](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Per-boot-Data-volume)
Mutable data on a PCC node is intended to be stored on a dedicated data volume, separate from the immutable ~[Signed System Volume](https://support.apple.com/guide/security/signed-system-volume-security-secd698747c9/web)~that contains the operating system. The dedicated data volume is encrypted with a storage-key hierarchy managed by the SEP. iOS features, like ~[Erase All Content & Settings](https://support.apple.com/guide/personal-safety/how-to-erase-all-content-and-settings-ips4603248a8/web)~, where user data can be quickly and reliably erased without modifying the system volume, use this same data-volume separation design.
With Ephemeral Data Mode enabled, the SEP randomizes this storage-key hierarchy at every boot. This cryptographically guarantees that no data-volume state written in a session can be read by any subsequent boot session.
On subsequent boot sessions, the mobile_obliterator boot task discards the previous encrypted data volume and reconstructs a clean volume from known-safe data, prior to loading other daemons.
[Anti-persistence](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Anti-persistence)
Some storage regions are not covered by the SEP’s key-hierarchy randomization nor validated during the boot process by ~[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)~. This includes persistent data stores such as NVRAM and the Preboot volume. These data stores have existing protections, designed to limit which processes can read and write data, that prevent anyone from accidentally or maliciously storing user data in them.
Our threat model assumes full node compromise where those protections are defeated. Accordingly, we also reset these data stores to a clean state on each system boot, so crafted values cannot be used by an attacker to influence subsequent boot sessions. These protections are implemented across several system components, including iBoot, MobileObliteration, and ~[darwin-init](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#darwin-init)~.
### Request Flow
Anonymous request routing is designed to ensure non-targetability.
[Overview](https://security.apple.com/documentation/private-cloud-compute/requestflow#overview)
![](pcc-guide/routing-overview~dark@2x%202.png)
The PCC request flow starts on the user’s device — the root of all security and privacy policies in PCC. When submitting a request to PCC, the user’s device validates attestation bundles provided by PCC and determines whether to trust those attestations and wrap the encryption key for the request to that PCC node.
The flow for a request goes through these steps:
The Apple Intelligence ~[orchestration layer](https://security.apple.com/documentation/private-cloud-compute/requestflow#Apple-Intelligence-orchestration)~ decides to route a request to a server-based model.
The user’s device ~[authenticates with PCC](https://security.apple.com/documentation/private-cloud-compute/requestflow#Client-authentication)~, PCC issues the device anonymous access tokens.
The user’s device ~[submits the request](https://security.apple.com/documentation/private-cloud-compute/requestflow#Network-transport)~ to PCC through the use of a third-party relay and our ~[encrypted request protocol](https://security.apple.com/documentation/private-cloud-compute/requesthandling)~.
Attestations of PCC nodes are ~[validated by the user’s device](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-validation)~, which wraps decryption keys for the request to the REK for these nodes.
The request is ~[decrypted and handled](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Request-handling)~ by a PCC node.
Let’s take a closer look at each of these steps.
[Apple Intelligence orchestration](https://security.apple.com/documentation/private-cloud-compute/requestflow#Apple-Intelligence-orchestration)
![](pcc-guide/ai-overview~dark@2x.png)
Apple Intelligence experiences are managed by an orchestration layer on the user’s device, which is responsible for:
Routing inference requests between on-device and server-based models
Prewarming on-device models and connections to server-based models
These tasks are handled by the modelmanagerd daemon, which in turn uses extensions to service requests for the on-device and server-based models. Requests to the server-based models in Private Cloud Compute are handled first by the PrivateMLClientInferenceProviderService extension and then passed to the privatecloudcomputed daemon. modelmanagerd is responsible for deciding how to prewarm and execute intelligence requests based on user activity and device context.
When the user invokes an Apple Intelligence feature, a prewarming step may be initiated to ensure that the device is ready to handle any intelligence requests. If needed, privatecloudcomputed executes its ~[authentication flow](https://security.apple.com/documentation/private-cloud-compute/requestflow#Client-authentication)~ and will ~[prefetch attestations](https://security.apple.com/documentation/private-cloud-compute/requesthandling)~. When the user triggers an inference request, modelmanagerd will route appropriate requests to the PCC extension.
A given intelligence feature may use multiple requests, and the requests may use different models and/or backends. modelmanagerd is aware of the relationship between these requests; it assigns a “Session UUID” to related requests to the same model and a “Session Set UUID” for related requests across all models. These identifiers are distinct from any request identifiers that are shared with PCC, and the mapping between these identifiers is not shared with Apple.
[Client authentication](https://security.apple.com/documentation/private-cloud-compute/requestflow#Client-authentication)
PCC applies limits to its use to prevent malicious or fraudulent use. This includes:
Limiting which devices or users can access the service
Imposing reasonable rate limits on those users and devices
However, the system’s non-targetability requirement means it’s challenging to implement these limits. We cannot simply require authentication when submitting a request using an account or device credential. Instead, PCC implements these policies, while preserving client anonymity and non-targetability, by using an identity service that vends cryptographically unlinkable tokens.
![](pcc-guide/private-cloud-compute-client-authorization-flow~dark@2x.png)
The client authorizes itself and sends a Token Granting Token (TGT) Request to the PCC Identity Service, which is a separate entity from PCC and plays no role in request routing or processing (step 1 in the flow diagram above).
The PCC Identity Service verifies that a specific client and device are eligible to use PCC, and issues a TGT that serves as proof of eligibility (step 2). TGTs are issued on a per-user, per-device basis and are built using RSA Blind Signatures, as detailed in ~[RFC 9474](https://www.rfc-editor.org/rfc/rfc9474.html)~and used in Privacy Pass (~[RFC 9578](https://www.rfc-editor.org/rfc/rfc9578)~). The blindness property of RSA Blind Signatures guarantees that the TGT Redemption is cryptographically unlinkable to the TGT Request that the client sent, including authentication information.
The client sends the TGT to the Token Granting Service, along with a Batch Request for One-Time Tokens (OTT) (step 3).
The Token Granting Service checks that the TGT is valid and that it has up-to-date fraud data for that TGT. If updated fraud data is required, this is indicated to the client, which reissues the request following the ~[fraud data protocol](https://security.apple.com/documentation/private-cloud-compute/requestflow#Fraud-data-protocol)~.
The Token Granting Service then returns a batch of OTTs (step 4), enforcing the appropriate rate limit based on the TGT’s fraud data.
For each request to PCC, the client attaches one OTT as proof that it is authorized by the Token Granting Service to use PCC (step 5).
OTTs are also built using RSA Blind Signatures, which means that the OTT Redemption is publicly verifiable and is also cryptographically unlinkable to the OTT Batch Request that was sent by the client alongside the TGT Redemption. These properties allow the PCC service to use the OTT public key to verify that the OTT is valid without learning any information about the user or device from which the request came (step 6).
The client includes the TGT in the body of the encrypted request, which only the PCC node can decrypt. The node checks that the TGT is valid, and if so, it processes the request (step 7). The inclusion of the TGT in the body of the encrypted request provides for future abuse-mitigation options, but this is not currently implemented.
Once a client runs out of OTTs, it can request another batch of OTTs by repeating steps 3 and 4. Because the TGT Redemption is cryptographically unlinkable to the TGT Request that the client sends alongside its authorization information, requesting more OTTs doesn’t leak any information about a specific client’s PCC usage pattern.
[Fraud data protocol](https://security.apple.com/documentation/private-cloud-compute/requestflow#Fraud-data-protocol)
The Token Granting Service (TGS) uses a Fraud Detection Service (FDS) to make anonymous fraud determinations about transacting entities. We designed the fraud data exchange protocol to preserve privacy and non-traceability in the following ways:
Minimize the data that is sent from the fraud scoring service to TGS, with limits on the size of data enforced by the user’s device.
Ensure that requests for fraud scoring and TGT redemption cannot be linked to each other.
The fraud data associated with a TGT is assigned or updated using the following process:
The PCC client issues a batch request for One-Time Tokens (OTTs) to the Token Granting Service (TGS).
TGS responds to the client with a data-refresh challenge, which includes up to 8 bits of reported data.
Client makes a request to the FDS service and provides the 8 bits of data received from TGS.
FDS provides the client with an updated data value in a signed message, using blind signatures.
Client reissues the OTT request to TGS while presenting the updated data value provided by FDS.
TGS then returns OTTs after applying appropriate controls (such as rate limit) based on the updated data associated with the TGT.
TGS continues to associate the updated data with the TGT, which ensures the data is used for subsequent OTT requests.
If and when TGS determines that a new fraud data update is required, it reinitiates this process.
[Network transport](https://security.apple.com/documentation/private-cloud-compute/requestflow#Network-transport)
Apple routes all requests to PCC through a third party to conceal the source IP addresses from the PCC infrastructure. Requests are protected with the chunked variant of the ~[Oblivious HTTP](https://www.rfc-editor.org/rfc/rfc9458.html)~ protocol.
In this routing approach, clients:
Encrypt requests using ~[Hybrid Public Key Encryption](https://www.rfc-editor.org/rfc/rfc9180.html)~ (HPKE) and the public key configuration of Apple’s Oblivious Gateway (OG).
Randomly select among multiple Oblivious Relays (ORs) operated by distinct third parties, currently ~[Cloudflare](https://blog.cloudflare.com/building-privacy-into-internet-standards-and-how-to-make-your-app-more-private-today/)~ and ~[Fastly](https://docs.fastly.com/products/oblivious-http-relay)~.
Send messages to the OG through the OR, which provides a secure HTTP proxy.
Like ~[iCloud Private Relay](https://www.apple.com/icloud/docs/iCloud_Private_Relay_Overview_Dec2021.pdf)~, clients use HTTP/3 to communicate with the ORs and fall back to HTTP/2 when HTTP/3 is not possible. They use ~[Publicly-Verifiable RSA Blind Signature Privacy Pass tokens](https://www.rfc-editor.org/rfc/rfc9578.html#name-issuance-protocol-for-publi)~ to authenticate to both the ORs and OGs. Clients present different tokens, signed by different keys, to each OR and OG.
The Oblivious HTTP key configuration and the signing key that PCC uses for the TGT or OTT require careful considerations to ensure that these key configurations cannot be used to identify and target specific devices. For example:
Oblivious HTTP: If a unique OHTTP public key were to be provided to a specific client, the Oblivious Gateway that decrypts a request might identify which requests were submitted by that client through its use of this public key. This scenario is discussed in the ~[Privacy Considerations](https://www.rfc-editor.org/rfc/rfc9458.html#name-privacy-considerations)~ section of RFC 9458.
TGT and OTT Tokens: If unique token public keys were provided to a specific client, the client’s token-issuance requests would use those keys and receive blinded tokens signed with unique keys. These client devices might then be identified during token verification based on its use of one of these tokens signed by these unique keys.
PCC is designed to mitigate these targeting concerns by using the Apple Transparency Service described in ~[Release Transparency](https://security.apple.com/documentation/private-cloud-compute/releasetransparency)~. The keys advertised to clients are published to the transparency log, and clients confirm that the keys they receive have been recorded in the transparency log. Security researchers can use the transparency log to verify that only one set of keys is in use in a given time period.


### Attested Request Handling
We designed the PCC application protocol to preserve client anonymity and efficiently route traffic through the PCC fleet.
[Overview](https://security.apple.com/documentation/private-cloud-compute/requesthandling#overview)
Once a PCC node boots, darwin-init loads the relevant cryptexes, and the system enters ~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~. Then, the CloudBoard project manages the node’s lifecycle. CloudBoard is a collection of daemons that manage incoming requests before passing them off to specific applications that handle LLM processing, such as The Inference Engine (TIE).
CloudBoard begins by creating a SEP-protected Request Encryption Key (REK) pair, to which user devices encrypt inference requests. Then, it uses the CloudAttestation framework to assemble an attestation bundle for this key pair. The attestation bundle contains all the information necessary for client devices to determine whether the node is securely configured and is running an inspectable release. When TIE signals that it’s ready, CloudBoard registers with the PCC gateway to indicate it’s able to receive requests.
[Application Protocol](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Application-Protocol)
The first step in the PCC application protocol happens before an inference invocation occurs, often overnight. The user’s device makes a query using Oblivious HTTP to the PCC Gateway to prefetch a set of attestations. The device can use these attestations later in inference queries. If any of the nodes from which the device received a prefetched attestation are free, the PCC Gateway can route the query directly to that node, which avoids the need for an extra network round trip before inference begins.
These prefetched attestations raise an additional anti-targeting concern. Because prefetched attestations are a client-specific state, the client needs to mitigate the risk that the PCC Gateway might fingerprint a client based on the attestations that it uses. The client achieves this by using each attestation returned in a prefetch call only once before requiring a new prefetch call, ensuring there’s no correlation in the attestations used across requests from the same client device.
When it comes time to submit a request to PCC, the client generates a unique symmetric Data Encryption Key (DEK) for each request, which it uses to encrypt the request payload.
The PCC Gateway provides the client with attestations, covering the Request Encryption Key (REK), for a set of nodes eligible to serve a request. Using the flow described in ~[Node validation](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-validation)~, the client validates the attestations to verify that the nodes are candidates to handle the request. For each node with a client-validated attestation, the client wraps the DEK using ~[Hybrid Public Key Encryption](https://www.rfc-editor.org/rfc/rfc9180.html)~ (HPKE), as defined in the ~[Oblivious HTTP specification](https://www.rfc-editor.org/rfc/rfc9458.html#name-hpke-encapsulation)~. The recipient key for each HPKE operation is the REK, and the client’s sender key is a unique ephemeral key, generated randomly by the client for each node.
The PCC Gateway then routes the request to a specific PCC node, and once the node is ready to return a response, the node uses the HPKE envelope to generate a key for response data. The node then uses this key, instead of the DEK, to encrypt its response so the client knows which node sent the response data.
This collection of keys provides an end-to-end encrypted, bidirectional tunnel, cryptographically tied to the REK and the node attestation. This tunnel enables transmission of request and response data, as well as protocol-control messages, between the user’s device and a PCC node.
To provide the client with attestations from appropriate PCC nodes, the PCC Gateway must be able to determine which nodes can handle a specific request. To enable this, a small amount of metadata is passed by the client to the PCC Gateway outside of the HPKE-protected tunnel. This metadata is protected by Oblivious HTTP and not observable by third parties. This metadata doesn’t contain personally identifiable information, or any information that might allow for deanonymizing the user or compromising their data.

In detail, the steps of this flow are:
**Device**: Generate the Data Encryption Key (DEK).
**Device**: Assemble the request by encrypting the request body with the DEK and constructing a plain text envelope with any metadata required to route the request.
**Device**: Submit the request to the PCC Gateway. If any pre-fetched and validated node attestations are available, provide the symmetric keys wrapped to those nodes as a sidecar.
**PCC Gateway**: Search for an appropriate node to handle the request. Determine if client-provided pre-fetched HPKE keys correspond to acceptable nodes; if found, skip to (6). Otherwise, select candidate nodes and return their attestations to the client.
**Device**: Verify each attestation provided by the PCC Gateway. If valid, provide the PCC Gateway with an HPKE-wrapped copy of the DEK via the same connection. Otherwise, reject the node.
**PCC Gateway**: Select a node from the list of candidates and notify the client of the selection.
**PCC Gateway**: Forward the node-specific wrapped DEK to the selected node, along with the encrypted invocation request.
**Node**: Perform the inference, generating and sending encrypted response tokens back to the client, routed via the PCC Gateway.
At the conclusion of this procedure, the node can begin delivering incremental results, if any, and then the final result data to the client. The response is encrypted using the HPKE-derived key established with the client.
[Node validation](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-validation)
Before a user’s device releases the DEK to a PCC node — and therefore grants access to the private request — the node needs to pass three validations performed by the CloudAttestation framework:
The PCC node possesses a valid provisioning certificate issued by the Data Center Attestation Certificate Authority, to demonstrate the node is authentic Apple hardware.
The SEP Attestation, as packaged by ~[CloudAttestation](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cloud-Attestation)~, indicates the system is in the expected security state to confirm that the expected strict security policies are being applied by the node.
The transparency log includes the software measurements of the PCC node to ensure the software is subject to our ~[Release Transparency](https://security.apple.com/documentation/private-cloud-compute/releasetransparency)~ promises.
The validation of the DCACA certificate is a standard X.509 certificate validation, but the other steps involve more specific processes.
To validate the SEP Attestation, the CloudAttestation framework validates the authenticity and integrity of the attestation itself and also that the attesting DCIK public key matches the public key of the provisioning certificate.
The framework then evaluates a security policy to assert the following security properties:
The hardware-attested SEAL_DATA_A register contains the SHA2-384 hash of the booted AP Image4 ticket.
The SEP-attested Cryptex Manifest Register matches a replay of the hash operations of all cryptexes and that the register is locked.
The SEP-attested Configuration Seal Register matches a replay of the hash operation of darwin-init configuration.
The SEP-attested REK key options include OS-bound and sealed-hashes-bound as defense-in-depth to ensure that encryption keys with access to user data are invalidated on system state changes.
The SoC is production-fused.
~[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)~ and ~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~ are enabled.
Developer mode is disabled.
The darwin-init config sets config-security-policy to customer.
To validate the software measurements, CloudAttestation needs to ensure that our Release Transparency process has logged these measurements for public inspection. This logging enables our verifiable transparency guarantee: only code that has been publicly logged for inspection is granted access to users’ data. To accomplish this, CloudAttestation’s Release Inclusion Verification process validates consistency and inclusion proofs provided as part of the attestation bundle against the local milestones available on the device.
To enable security researchers to inspect the attestations being returned to their devices, the Apple Intelligence Report includes information about the attestations used in each request. For more information about viewing these logs and their contents, see ~[Appendix: Apple Intelligence Report](https://security.apple.com/documentation/private-cloud-compute/appendix_appleintelligencereport)~.
[Node selection](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-selection)
As discussed in ~[Attested Request Handling](https://security.apple.com/documentation/private-cloud-compute/requesthandling)~, PCC nodes with attestations that are considered for use in a specific request come from two sources:
Prefetched: locally cached attestations acquired during a prefetch step.
Just-In-Time: attestations provided by the PCC Gateway during the request flow.
The ~[Node validation](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-validation)~ process enables our verifiable transparency property, but to enable our non-targetability property we need to consider the process by which a device determines the set of PCC nodes to which it encrypts a request. A specific request should be able to be decrypted only by a subset of PCC nodes, so if a single node is compromised, it’s not able to decrypt more than a small portion of incoming requests. This approach reduces the value of a targeted compromise by ensuring that such an attack is unlikely to decrypt requests from a specific user or device, because the set of nodes for that request is unlikely to contain the compromised node.
There is a natural tension between this goal and optimally selecting nodes to service requests: if there are fewer nodes that can decrypt a request, it’s less likely that a node is available to immediately service an incoming request. Each PCC node can handle a limited number of requests at a time, and some requests can take several seconds, so PCC must avoid queuing multiple requests on a small set of nodes. To ensure that PCC can operate efficiently and that slow clients cannot cause a denial of service, PCC must also avoid reserving capacity on a node until an incoming request is fully received and able to be processed.
PCC’s node selection process therefore tries to balance these two goals simultaneously:
Ensure that most requests experience no additional latency due to queueing or additional round trips.
Encrypt to the minimum required set of PCC nodes.
Balancing these goals requires carefully tuning the size *k* of the set of PCC nodes to which a request is encrypted: it must be large enough to accomplish our latency goals but minimized to ensure non-targetability. To strike the right balance, we started by defining our desired quality of service: **PCC needs to be able to handle 99 percent of incoming requests without any additional latency while operating at an average of 90 percent utilization.**
[Selecting the size of k](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Selecting-the-size-of-k)
For our initial release of PCC, we used simulations and queueing theory to determine the value of *k* required to consistently meet our desired quality of service. This represents an initial worst-case scenario, and we’ll continue to evaluate it against real-world data to determine whether we can reduce it without impacting user performance.
To determine this initial value of *k*, PCC’s design needs to consider two cases:
The client provides prefetched attestations with the initial request body, which PCC uses to avoid an additional round trip with the client. To meet our goal of handling 99 percent of requests without queuing or falling back to just-in-time attestations under 90 percent utilization, simulated with Poisson distributed-request arrival times, the client must be able to provide 60 prefetched attestations.
The PCC Gateway receives a request without prefetched attestations and must determine the set of just-in-time PCC node attestations that it returns to the client. To minimize the requirement on *k* in this case, the PCC Gateway has an intelligent algorithm which uses its understanding of the current service state to pick the set of returned nodes that are likely to be free when the request is ready to be processed. This enables PCC to minimize the requirement on *k* for just-in-time attestations to *k*=27, and *k*=15 in regions with low latency to PCC nodes.
Some scenarios might result in none of the prefetched attestations being valid, such as failover between data centers, so the client must be able to provide both of these sets of attestations in the same request context, producing a worst-case value of *k*=87, or *k*=75 in optimal geographic locales. Minimizing the value of *k* is important to ensure that PCC’s security is robust against targeted hardware attacks, so we will continue to look for opportunities to reduce the maximum value of *k* and evaluate the real-world performance of running with smaller values.
The number of just-in-time attestations provided for a request is determined by the PCC Gateway, which often returns fewer attestations than allowed by these limits if system utilization permits. To protect limits from being exceeded if the PCC Gateway is compromised, the client device caps the number of attestations it uses at these values, regardless of how many attestations the PCC Gateway offers. The PCC client also supports a server-provided configuration so we can dynamically lower (but not raise) the client’s limit on *k* to evaluate the impact of smaller *k* values on performance. This configuration is fetched via an OHTTP relay, ensuring that an attacker cannot target changes to this value at a specific user.
In addition to our efforts to minimize *k*, we also leverage two mechanisms to validate that the PCC Gateway is distributing those *k*attestations across the PCC fleet appropriately:
For users who opt-in to sharing analytics data with Apple, the PCC client reports statistics that describe the flatness of the distribution of PCC nodes provided by the PCC Gateway.
Security researchers can use the Apple Intelligence Report to view the hardware identity of the PCC nodes used in each request and to confirm they are appropriately distributed. For more information, see ~[Appendix: Apple Intelligence Report](https://security.apple.com/documentation/private-cloud-compute/appendix_appleintelligencereport)~.
[Request handling](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Request-handling)
Once the user’s device encrypts a request to a set of PCC nodes, and the PCC Gateway routes the request to one of those nodes, the node is ready to begin processing.
PCC nodes manage and coordinate requests using the CloudBoard family of daemons. cloudboardd is the central coordinator daemon, and it uses a set of helper processes that perform the cryptographic operations for the request before finally passing the request along to the inference engine (TIE). These helper processes include cb_attestationd, cb_jobauthd, and cb_jobhelper.
[CloudBoard daemons](https://security.apple.com/documentation/private-cloud-compute/requesthandling#CloudBoard-daemons)

cloudboardd manages any interactions with the PCC Gateway and associated services. This includes exposing a node status and health endpoint, publishing node attestations, and accepting new incoming requests routed to the node. cloudboardd receives node attestations from cb_attestationd via XPC. Because cloudboardd accepts incoming network connections, it exposes an attack surface outside the trust boundary. This separation ensures that cloudboardd has no access to keys that could be used to decrypt request data.
cloudboardd also interacts with the fleet management system indirectly via a RemoteServiceDiscovery (cf. remoted(8)) endpoint that it exposes locally to the BMC. The BMC queries node state via this endpoint and forwards it to the fleet management system.
Each time cloudboardd accepts an incoming request from PCC Gateway, it creates a new instance of cb_jobhelper to manage that request. Each request has its own dedicated ~[HTTP/2](https://http2.github.io/)~ stream, and cloudboardd proxies the incoming and outgoing data for the associated stream between the PCC Gateway and the associated cb_jobhelper. The dedicated cb_jobhelper performs the cryptographic handshake with the client device and decrypts the streamed request messages using the attested SEP-backed REK provided by cb_attestationd. To authorize the request, cb_jobhelper extracts the client’s TGT from the request, verifies its signature with the public TGT signing key provided by cb_jobauthd, and then verifies that the OTT was derived from the TGT.
cb_jobhelper then works with its paired application instance, such as tie-cloud-app, discussed in ~[Stateless Inference](https://security.apple.com/documentation/private-cloud-compute/statelessinference)~, to handle the request. This separation helps isolate faults and ensures that cb_jobhelper can report errors or crashes during request processing back to cloudboardd and the requesting device. Response messages received from the dedicated tie-cloud-app are encrypted by cb_jobhelper and forwarded to cloudboardd.
[Runtime configurable properties](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Runtime-configurable-properties)
The CloudBoard infrastructure supports runtime-configurable properties provided by the CloudBoardPreferences framework, which manages their state via the cb_configurationd daemon. This daemon periodically checks for new configuration updates and applies them, keeping a cache of the current state locally. Because these properties can change at runtime, they are not part of the node’s attested state. They are considered untrusted in the PCC threat model and must not be able to change the security or privacy properties of the system.
To enable consumers of these runtime-configurable properties to be easily auditable, we require that they use the CloudBoardPreferences framework and the associated cb_configurationd daemon to access the data. As CloudBoardPreferences is deployed as part of a cryptex, it is not used by any OS components, only by daemons in the PrivateCloudSupport cryptex. Since CloudBoardPreferences clients must be able to communicate with cb_configurationd to use this interface, these components can be identified for auditing by the presence of the com.apple.security.exception.mach-lookup.global-name entitlement with the service name com.apple.cloudos.cb_configurationd in the corresponding array.

### Stateless Inference
The PCC inference engine enables high performance while keeping user data private.
[Overview](https://security.apple.com/documentation/private-cloud-compute/statelessinference#overview)
To power LLM functionality in PCC, we designed a custom inference server — The Inference Engine (TIE) — and inference framework — Metal LM. MetalLM uses Metal-based shaders and compute kernels to perform inference computation.
TIE and MetalLM also support distributing inference across multiple SoCs to process requests with reduced latency and higher throughput. PCC supports ~[distributed inference](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Distributed-inference)~ across a grouping of up to eight nodes, together called an *ensemble*, with a leader node that’s responsible for accepting incoming requests and coordinating the ensemble’s activities.
[Language model inference](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Language-model-inference)
We designed foundation language models for Apple Intelligence to perform a wide range of tasks efficiently, accurately, and responsibly. This includes Apple Foundation Model server (AFM-server), the model used by PCC. You can learn more about the architecture and training of AFM-server in the ~[Apple Intelligence Foundation Language Models paper](https://machinelearning.apple.com/research/apple-intelligence-foundation-language-models)~ and our blog post ~[Introducing Apple’s On-Device and Server Foundation Models](https://machinelearning.apple.com/research/introducing-apple-foundation-models)~.
Notable aspects of the inference process include:
The model can be specialized for specific tasks using runtime-swappable adapters, which are small neural network modules that plug into the base model.
The user’s device submits inference requests by providing values which TIE composes with a prompt template to produce the model’s prompt string.
The model uses a tokenizer based on ~[SentencePiece](https://github.com/google/sentencepiece)~. TIE is responsible for tokenizing the string prompt and converting output tokens back into strings.
TIE might leverage speculative decoding using a small draft model to speed up inference.
Some use cases may prescribe a grammar for the output, in which case a framework for constrained decoding ensures that sampled tokens meet the prescribed grammar.
Model output is streamed to the user’s device as tokens are produced. Padding is applied to prevent ~[token-length side-channel attacks](https://arxiv.org/abs/2403.09751)~.
[The Inference Engine](https://security.apple.com/documentation/private-cloud-compute/statelessinference#The-Inference-Engine)
TIE, the inference server of PCC, handles the application-level logic of executing the inference requests that user devices submit to PCC. Requests are initially received on the PCC node by CloudBoard, which is responsible for implementing the cryptographic protocol with a user’s device, and are then handed off to TIE for processing. Both TIE and CloudBoard use a family of daemons to ensure robustness and provide isolation in the event of an exploit.
![](pcc-guide/distributed-inference~dark@2x.png)
When the system boots, the tie-model-owner process uses the ModelCatalogSE framework to load the model weights, adapters, and associated parameters from disk into memory. ModelCatalogSE provides an index of model data and metadata — for example, tokenizers, stop tokens, and prompt templates — derived from ~[model and adapter cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Foundation-model-and-adapter-cryptexes)~ on the PCC node. The long-lived tie-model-owner process creates and vends persistent, read-only memory references for the model weights to avoid reloading these large assets from disk.
The inference components are orchestrated by a single tie-controllerd daemon, which executes as part of node initialization and coordinates the remaining processes. The tie-controllerddaemon acts as the main control system of TIE and handles interfacing with CloudBoard to provide real-time updates on the health of the system. tie-controllerd also coordinates the recycling of the inference process in addition to initiating periodic key rotations of the CIO mesh, which we discuss below. Lastly, tie-controllerd interfaces with CloudBoard’s ~[Runtime configurable properties](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Runtime-configurable-properties)~ to fetch prompt deny lists, which are lists of blocked inputs that might compromise system stability.
When a request arrives at a PCC node, TIE decodes and pre-processes it in an ephemeral, per-request process: an instance of tie-cloud-app. The system uses process pooling to avoid the runtime cost of process spawning. Process pools consist of pre-instantiated cb_jobhelper and tie-cloud-app pairs that stand ready to serve a request.
Once CloudBoard selects a tie-cloud-app instance to handle a request, tie-cloud-app:
Deserializes the incoming Protobuf-encoded request
Validates that the request parameters are safe
Tokenizes the string-based prompt using the tokenizer specified by the model cryptex
TIE performs tokenization in a per-request process to isolate parsing of untrusted string input. We use a per-request process instance to help ensure that if a process compromise were to occur, it would not provide access to the request data of other users. Any intermediate request data is discarded when the request is completed and the process terminates.
Upon initial processing of the request, the tie-cloud-app sends the request to a shared tie-inference process that performs the inference using MetalLM. The request data includes the tokenized input, the identifiers of the model and adapter to use for inference, sampling parameters, and, if applicable, the constrained decoding grammar. To minimize the risk that the inference host process unexpectedly retains user data beyond the lifetime of a single request, the tie-controller periodically terminates the inference process and starts a new instance. We designed this approach to ensure that data processed within a previous instance of the inference host is inaccessible to an attack that might compromise a future instance.
Some Apple Intelligence features expect the LLM model to produce output in a specific format. To enable the model to match the expected output format, TIE supports using a constrained decoding process provided by the TokenGenerationSE framework. This imposes constraints on the sequence of tokens that TIE can generate, specified using a BNF-based grammar that is contained in the asset cryptex. Before the MetalLM framework generates each token, TokenGenerationSE generates a mask of valid potential tokens. Tokens that fall outside of this mask are rejected by TIE, ensuring that MetalLM generates valid tokens and text.
[Distributed inference](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Distributed-inference)
Distributing requests across multiple nodes presents some unique challenges: we must not weaken PCC’s verifiable transparency promises or extend our trust boundary outside the scope of the compute nodes.
The nodes in an ensemble are connected in a mesh, so they can exchange data over a high-performance interconnect using USB4. Ensembles succeed or fail together, and the loss of any ensemble member requires all nodes to reboot. Ensembles have a leader that coordinates the distribution of work. In turn, TIE and MetalLM divide the LLM computation among nodes in the ensemble. To do this, the AppleCIOMesh framework provides a number of data-distribution primitives (similar to those offered by ~[Message Passing Interface](https://www.mpi-forum.org/docs/mpi-4.1/mpi41-report/node10.htm#Node10)~) such as peer-to-peer messages, ~[gather-to-all](https://www.mpi-forum.org/docs/mpi-4.1/mpi41-report/node126.htm#Node126)~, and broadcast messages. TIE (via the MetalLM framework) sends data that is fully encrypted by AppleCIOMesh to the appropriate set of nodes within an ensemble to parallelize the LLM computation.
When operating in distributed inference mode, TIE splits the input prompt tokens among all nodes in the ensemble to produce the first output token. TIE uses the common technique of a key-value cache (KV cache) to avoid recomputing values for tokens that it has already processed. As computation progresses layer by layer in the model, each node initiates a broadcast-and-gather operation to send its KV cache and in turn receive the KV caches of the remaining nodes in the ensemble. To produce additional tokens, nodes exchange tensors per layer at the start and end of each layer, via broadcast-and-gather operations. The leader node of the ensemble samples tokens, checks for stop sequences, and formats token response messages to the client.
The tie-controllerd on the leader node coordinates activities across the rest of the follower nodes by communicating with the followers over a TLS-protected GRPC connection, using a pre-shared key. tie-controllerd on the leader node initiates control messages to inform the nodes to start a given inference, check health status, and perform periodic inference-process exits. During each inference-process exit event, tie-controllerd informs ensembled to rotate the underlying encryption key of the CIO mesh.
AppleCIOMesh is a new kernel extension that provides a secure and efficient low-latency transport among the PCC nodes in an ensemble. The kernel extension is configured by AppleComputeEnsembler, which supplies the primary seed generated by CloudAttestation to the kernel extension. AppleCIOMesh secures all data on the transport with AES-GCM following ~[best practices from NIST](https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-38d.pdf)~. Data on the transport is encrypted by AppleCIOMesh with AES-GCM 128 using a unique symmetric key for each node. The GCM anti-replay value is 96 bits: 64 bits of random data and a 32-bit counter. The 64-bit random data portion of the anti-replay value is unique per node and derived from the primary seed using ~[HKDF](https://www.rfc-editor.org/rfc/rfc5869.html)~. Each invocation of GCM increases the counter, and if the invocation amount reaches 2^32, the system triggers a catastrophic error failure. The counter is implicit and not sent over the wire. Any data that fails to decrypt is a catastrophic failure, and the ensemble is taken offline. In addition, the system also treats link loss as a catastrophic failure. These failures require a reboot and reconfiguration of the entire ensemble.
[Ensemble attestation](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Ensemble-attestation)
The leader of an ensemble is the only PCC node that is exposed to client devices and capable of receiving incoming inference requests. Client devices verify only the attestation state of the leader to avoid needing to verify the attestation of every node. Because the device relies on the leader node to transitively attest to the state of the ensemble, the leader must maintain consistency across the ensemble.
To do so, the leader node ensures that:
Each follower node has a valid attestation, signed by a DCIK certified by the Provisioning Certificate Authority.
The software measurements of all follower nodes are identical to the leader’s software measurements.
The chip ID, board ID, SoC fusing bits (production status, security mode, and security domain) of all follower nodes are identical to those of the leader.
The states of restricted execution mode, ephemeral data mode, and developer mode of all follower nodes are identical to those of the leader.
The config-security-policy key within darwin-init for each follower is set to the same value as the leader.
A darwin-init entry on the leader defines the ensemble configuration and includes the UDIDs of all follower nodes. A daemon called ensembled consumes this configuration and uses CloudAttestation to perform a mutually attested key exchange with each leader-follower pairing. The provisioning-certificate fingerprints for the entire ensemble are also included in the secure-configsection of the attestation bundle, which CloudAttestation consumes to validate the ensemble topology for correctness — allowing a maximum of two chassis consisting of no more than four nodes each. Client devices can also observe this paper trail of certificate fingerprints when validating the attestation bundles of leader nodes.
Because the configuration consumed from secure-config is irrevocable and can be applied only once by darwin-init, the registered ensemble topology remains immutable for the entirety of the boot session. Therefore, new ensemble formations can complete the pairing process only if the nodes are rebooted with the correct darwin-init that contains the new topology within the secure-config section.

To begin the ensemble-pairing process, the leader securely generates a random 32-byte primary seed using ~[CryptoKit](https://developer.apple.com/documentation/cryptokit/)~, which must be securely distributed by AppleCIOMesh to each follower. This seed value is used by each node as input to ~[HKDF](https://www.rfc-editor.org/rfc/rfc5869.html)~-SHA384 to generate a unique-per-sender AES-128-GCM table of keys. Each follower requests the shared secret from the leader by generating an ephemeral SEP-managed NIST P-256 Elliptic Curve Diffie-Hellman (ECDH) key and accompanying attestation bundle in its request, utilizing the same mechanism as described in ~[Cloud Attestation](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cloud-Attestation)~.
Upon receipt of this request, the leader validates the attestation bundle, which upon verification provides a trusted provisioning certificate, UDID, and recipient public key of the follower node. The attestation validation process in the ensemble mesh scenario is identical to how clients validate leaders, except that the software measurements are not verified against the transparency log. Instead, all nodes in an ensemble verify that their peers are running the same PCC release. This verification provides assurance that the peer node is running with a verifiably transparent hardware and software configuration.
The leader node uses CryptoKit’s ~[HPKE-Sender](https://developer.apple.com/documentation/cryptokit/hpke/sender/init%28recipientkey:ciphersuite:info:authenticatedby:%29)~ API in authenticated mode with ephemeral SEP-managed NIST P-256 ECDH keys to send an ~[AES-GCM Sealed Box](https://developer.apple.com/documentation/cryptokit/aes/gcm/sealedbox)~ of the primary seed in its response. The recipient public keys of the remote follower nodes are authenticated using the attestation-bundle validation process described above.
Follower nodes receive both the encrypted primary seed and attestation bundle of the sender in the response. The follower validates the leader’s attestation bundle to establish trust that it received an encrypted message from the correct UDID and sender public key. It can then pass the sender’s public key to CryptoKit’s ~[HPKE-Recipient](https://developer.apple.com/documentation/cryptokit/hpke/recipient/init%28privatekey:ciphersuite:info:encapsulatedkey:authenticatedby:%29)~ API in authenticated mode to unseal the encrypted primary seed if, and only if, the message came from the trusted leader node.
The pairing process is repeated for all seven peer nodes, after which a shared secret seed exists between all members of the ensemble. A table of unique-per-sender AES-128-GCM keys is generated by AppleCIOMesh, which is computed with HKDF-SHA384 using the shared secret seed as the input key material and the nodes’ position in the ensemble topology as the input salt. Key rotation is initiated periodically by TIE, during which the initial pairing process is repeated with a new primary seed, new HPKE sender and recipient keys, and corresponding attestation bundles.
### Release Transparency
PCC attestation capabilities support independently verifiable transparency.
[Overview](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#overview)
A pillar of Apple’s commitment to Private Cloud Compute’s transparency is the PCC transparency process. We built strong ~[remote attestation](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cloud-Attestation)~ capabilities that enable user devices to determine whether to send private requests to a PCC node by first receiving trusted cryptographic measurements of the node’s operating system and all its loaded cryptexes. We publish expected measurements — which correspond to release builds of PCC software — to a public, append-only cryptographic transparency log. User devices send private requests to PCC nodes only if their runtime measurements are present in the transparency log, which ensures the measurements refer to an authorized software build that security researchers can inspect.
![](pcc-guide/release-transparency~dark@2x%202.png)
The Apple Transparency Service, which also enables ~[Contact Key Verification](https://security.apple.com/blog/imessage-contact-key-verification/)~, provides a log with the following properties:
**Transparency**: The log is publicly auditable, with all log entries available for inspection. Independent parties can verify that devices have the same view of the log as their own audit tooling.
**Tamper resistance**: The transparency log is backed by a Merkle tree and is append-only. Any attempt to alter or remove an entry once it’s added disrupts the hash tree in a way that independent parties can detect.
**Anti-Targeting**: Clients access the transparency log through a third-party MASQUE proxy (~[RFC 9298](https://www.rfc-editor.org/rfc/rfc9298.html)~), which conceals the IP address of the device and therefore significantly increases the difficulty of split-view attacks, for example targeting specific users with a different view of the log.
Security researchers monitoring the log can obtain the binaries referenced by each entry, reproduce their measurements, and inspect the software by running it in the ~[Private Cloud Compute Virtual Research Environment](https://security.apple.com/documentation/private-cloud-compute/virtualresearchenvironment)~. Researchers can also perform static analysis by disassembling the binaries.
[Release data structure](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Release-data-structure)
~[Remote attestation](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cloud-Attestation)~ cryptographically proves that a PCC node booted an operating system and loaded cryptexes that match the Image4 manifests provided in the attestation. To implement release transparency, CloudAttestation introduces the DER-encoded Release data structure, which describes the OS and cryptex Image4 tickets that compose a specific PCC release:
Release ::= SEQUENCE {
    version                 INTEGER(1),
    canonicalApTicket       OCTET STRING,
    canonicalCryptexTickets SET OF OCTET STRING,
}
Because Image4 manifests are personalized to each PCC node and contain device-specific information like device identifiers and anti-replay values, Release contains canonical representations of these tickets. Personalized tickets are canonicalized by setting the values of all tags listed in the uniq tag of the ticket to ASN.1 NULL (05 00). For a list of these fields and their purpose, see ~[Appendix: Secure Boot Ticket Canonicalization](https://security.apple.com/documentation/private-cloud-compute/appendix_uniqtags)~.
When a PCC node creates an attestation bundle, CloudAttestation computes the Release of its running software by converting the personalized tickets of the OS and loaded cryptexes to their canonical versions and constructing its Release. The node then requests cryptographic proofs from the Apple Transparency Service that the SHA256 digest of that Release is part of the public transparency log. CloudAttestation then includes these proofs in the attestation bundle.
When validating an attestation, CloudAttestation on the client independently computes the node’s Release from the personalized tickets in the attestation bundle and verifies the cryptographic proofs to confirm inclusion of the Release’s digest in the PCC transparency log.
[Binary transparency](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Binary-transparency)
For each Release in the transparency log, Apple is committed to publishing all relevant machine-code binaries for inspection and independent measurement. There are two sources for these code objects:
~[Image4 tickets](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)~ that directly describe boot firmware measurements
~[Trust caches](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Code-Signing)~, which contain code-directory hashes (CDHashes) for user-space executables
We publish both the boot firmware and user-space binaries to the Apple Content Delivery Network (CDN) for inspection, so researchers can verify that they match the measurements in their respective manifests and trust caches.
Under typical circumstances, we publish the binaries to the CDN roughly simultaneously with their entry into the transparency log. In cases where a binary contains sensitive content, such as unreleased security fixes which also apply to other Apple platforms, the release of the specific binary might be delayed up to 90 days until that content is available for the other platforms.
The CDN URLs for every PCC release are provided in the corresponding transparency log leaf metadata. CLI tooling provided as part of the ~[Virtual Research Environment](https://security.apple.com/documentation/private-cloud-compute/virtualresearchenvironment)~ downloads these images and validates that their cryptographic hashes align with their corresponding transparency log entry. The validation process begins by ensuring that the ~[Release](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Release-data-structure)~ provided within the log leaf metadata hashes to the same value described by the log leaf entry itself. The contained canonicalized tickets can then be used to validate their corresponding binary images.
[Release inclusion verification](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Release-inclusion-verification)
A consistent view of the transparency log across all clients and auditors is an important property to ensure comprehensive inspectability. To protect against split-view attacks, where malicious actors try to trick a target’s client device to trust a diverging history of the transparency log, connections to the Apple Transparency Service are routed through third-party MASQUE proxies. The top-level domains of these proxies are hard-coded in the client, so malicious configuration updates can’t arbitrarily re-route transparency traffic.
At least once a day, the Apple Transparency Service promotes a log head of the transparency log to a milestone. The client tracks these milestones and validates cryptographic consistency proofs to previous milestones, all the way to the beginning of the log to ensure it’s inherently consistent.
When a user’s device is verifying that the release of a PCC node is included in the transparency log, there are two possible cases to consider, depending on whether Apple Transparency Service generated the proof before or after it promoted a milestone containing that release:
**After**: The attestation bundle contains an inclusion proof of the release in a recent milestone.
**Before**: The attestation bundle contains an inclusion proof of the release in a recent non-milestone log head, and additionally a consistency proof from a recent milestone to that log head.
During the daily milestone download, the user’s device checks to make sure the log is consistent and confirms that it had previously been served consistency proofs that are also consistent with new milestones. Neither check is expected to fail in normal usage. If either fails, however, the device alerts the user only if the consistency error is not addressed by a new log within 7 days. This provides a grace period for recovery from operational errors or software bugs that corrupt the log, while still ensuring that any actual attack is discoverable by security researchers. In other words, in the unlikely case that the consistency failure was due to an attack, the user is alerted to the attack after the 7-day grace period because the attacker is unable to roll back the log to the pre-attack state.
Entries in the transparency log also have associated expiry timestamps that the client validates. Releases that are in use beyond the initial 14-day lifetime are republished to the log with a new expiry. For additional details of the protocol, see ~[Appendix: Transparency Log](https://security.apple.com/documentation/private-cloud-compute/appendix_transparencylog)~.
Because the transparency log is append-only, corruptions might require the creation of a replacement log populated with current data. In this case, Apple will publish a note on ~[security.apple.com](https://security.apple.com/)~ that explains the circumstances that required the new log. In addition, the Apple Transparency Service will continue to provide access to the previous log for inspectability.
[Apple Intelligence reports](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Apple-Intelligence-reports)
You can view the software components running in Private Cloud Compute using the ~[Apple Intelligence Report](https://security.apple.com/documentation/private-cloud-compute/appendix_appleintelligencereport)~. This report includes the ~[attestations](https://security.apple.com/documentation/private-cloud-compute/appendix_attestationbundle)~ used during each inference request your device submitted to Private Cloud Compute. The measurements of the ~[release structure](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Release-data-structure)~ describing the software components running on a PCC node are included in each attestation, as well as an inclusion proof for those measurements in PCC’s transparency log. For more details on how to inspect the transparency log, see ~[Inspecting Releases](https://security.apple.com/documentation/private-cloud-compute/inspectingreleases)~ and ~[Appendix: Transparency Log](https://security.apple.com/documentation/private-cloud-compute/appendix_transparencylog)~.
### Management & Operations
PCC nodes support privacy-aware management, observation, and debug capabilities.
[Overview](https://security.apple.com/documentation/private-cloud-compute/management#overview)
Like any large-scale service, PCC requires management, introspection, and debugging capabilities. These requirements are at cross purposes with our security model, which requires defensive barriers *against* things like introspection and debugging, regardless of who is performing them. We must balance effective administration of the service with our security goals to keep user data and identity confidential.
To ensure this balance, the PCC design considers each of the categories of telemetry required for a PCC node and the export points of such data. Each of those export points implements filtering logic that is designed to ensure that routine systems-management operations don’t create potential user-data exposures.
The rules imposed by these filtering mechanisms are included in the published software images so they can be inspected and verified by independent parties. We also routinely audit the rules to ensure they uphold to our corporate privacy principles and PCC’s privacy commitments.
For completeness, here are some management tools and techniques that we replaced or intentionally left out:
**Interactive Shell Access**. Interactive system access to an SRE presents significant privacy issues due to the large interface surface from which user data could be exposed.
**Sysdiagnose**. Sysdiagnose is disabled when a PCC node enters ~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~. Instead, PCC collects only specific and necessary data. This targeted approach to data collection differs from iOS and macOS which rely on ~[sysdiagnose archives](https://download.developer.apple.com/iOS/iOS_Logs/sysdiagnose_Logging_Instructions.pdf)~ to investigate issues.
**OS Analytics**. PCC disables the OS’s opt-in reporting of ~[analytics, diagnostics, and usage information](https://support.apple.com/en-us/108971)~, in favor of new purpose-built mechanisms that can apply PCC-specific privacy policies.
**Execution Traces**. Detailed execution-trace recording features, such as those that power Instruments’ ~[Time Profiler](https://help.apple.com/instruments/mac/current/#/dev44b2b437)~, provide high-resolution execution data which poses a risk of exposing user data via side-channels.
Additionally, the use of ~[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)~ is designed to prevent user data from surviving a system reboot, ensuring that the system cannot be reconfigured to reenable any of these tools while retaining user data.
[Metrics](https://security.apple.com/documentation/private-cloud-compute/management#Metrics)
The funnel point for all metrics reporting in PCC is the CloudMetrics, an implementation of the ~[swift-metrics](https://github.com/apple/swift-metrics)~ API backend. Software in the PrivateCloudSupport cryptex can use this implementation to log counters, gauges, and histograms. The observations are provided to the CloudMetrics framework, which sends them via XPC to the cloudmetricsd daemon, where they are reduced with local temporal aggregations. The aggregates are exported at a regular interval to an Apple metrics service via the ~[OpenTelemetry Protocol](https://opentelemetry.io/docs/specs/otlp/)~, an open observability standard.
Before exporting any data, the CloudMetrics framework consults a restrictive allow list of exportable metrics. CloudMetrics also controls the frequency of metric exports, and drops metrics based on their name, allowed dimensions, or range of valid values. The PrivateCloudSupport cryptex includes these configurations, and they are therefore covered by our verifiable transparency promises.
CloudBoard and TIE use CloudMetrics to record application-level metrics. The system also includes devicemetricsd, which collects system-level metrics — including metrics for performance and networking events — and routes them to CloudMetrics.
[Log filtering](https://security.apple.com/documentation/private-cloud-compute/management#Log-filtering)
The PCC node generates logs using the privacy-conscious ~[os_log\(3\)](https://developer.apple.com/documentation/os/os_log?language=objc)~ API, just like iOS and macOS. The splunkloggingddaemon provides an export service for this log data, which conforms to PCC’s privacy commitments and is tightly integrated with the os_log subsystem. Because each format string used with os_logresults in a distinct log event, splunkloggingd can impose filtering on a per-log-line basis.
splunkloggingd will exfiltrate a message only if the log line is permitted by its filtering rules. Like the permitted metrics configuration, the allow list that defines the permitted messages is included in the PrivateCloudSupport cryptex and subject to independent inspection. While os_log is used throughout the PCC software stack, only a select set of those messages are exported from the node.
An entry in the allow list is composed of the message sender (the Mach-O image calling os_log) and the format string. A stringent review process audits existing and new os_log calls in the PCC stack to determine which log lines are eligible for inclusion in this allow list. Because os_log format strings capture the type information of the variable arguments, privacy review also considers the data types included within a log line during this process.
splunkloggingd enforces this allow list by watching for logs from allowed Mach-O images. This streamed data contains both the fully composed log line with interpolated arguments and the original, uncomposed format string from the call site. By comparing the format string emitted against the allow list, the daemon is only able to forward logs that have been pre-approved.
[Crash reporting](https://security.apple.com/documentation/private-cloud-compute/management#Crash-reporting)
Triaging and analyzing user-space process crashes is a critical engineering task for all Apple platforms, and the PCC node OS uses the same crash-report generation infrastructure as macOS and iOS. This infrastructure is already built to be privacy-preserving, and for PCC, the system considers two types of data included in crash reports:
**Intrinsically safe**: Static data or system identifiers such as OS version or process ID. Intrinsically safe attributes are unable to accidentally reveal sensitive data because they are determined early at boot or in a context without any user data present.
**Process state dependent**: Data determined by inspecting the state of the crashing process, such as stack backtraces and register state. While already collected with strict user-privacy principles in mind, process-state-dependent attributes have some risk of accidentally revealing user data.
PCC’s privacy mitigations focus on reducing the amount of process-state-dependent data that can leave the PCC node. To handle this data, splunkloggingd defines two redaction behaviors, partial and full, which limit this data as follows:
| **Crash Log Attribute** | **Partial Redaction** | **Full Redaction** | **Notes** |
|---|---|---|---|
| Register state | Redacted | Redacted |  |
| Unresolvable stack frames | Redacted | Redacted | Bogus stack frames might indicate the stack being overwritten with runtime data. |
| Exception information |  | Redacted |  |
| Thread backtraces |  | Redacted | Only the last 32 frames of the crashing stack are preserved; all others are redacted. |
A maximum of three partially redacted logs is reported from each node per hour. Partially redacted reports are emitted randomly for 20 percent of crashes up to this limit.
In addition to crash logs, splunkloggingd also forwards panic logs. If a node panics, a report is written on reboot which splunkloggingd forwards to Splunk. This report has the same contents as those reported from iOS and macOS devices and is not further redacted on PCC. As the rate of system panics is naturally limited by their fatal nature, no additional rate-limiting is applied.
[Remote diagnostics and monitoring](https://security.apple.com/documentation/private-cloud-compute/management#Remote-diagnostics-and-monitoring)
PCC nodes have neither remote access nor local shells, so traditional methods of gathering administrative health data are not available. Instead, we built specific interfaces to collect health and diagnostic information via the CloudRemoteDiagnostics project and its cloudremotediagd daemon. This daemon uses system interfaces to directly collect a limited set of statistics and doesn’t spawn helper processes for this purpose. It makes these interfaces available only to its paired BMC via the in-chassis network.
We designed each function of CloudRemoteDiagnostics to minimize the risk of user data exposure. For example, the daemon exposes functionality to capture stack traces of potentially misbehaving processes. As with crash logs, these backtraces pose only a minor risk of leaking user data, but if applied at sufficient frequency, this functionality might expose the system to a side-channel attack. To mitigate this risk, the daemon imposes a rate limit on this functionality, limiting the effective bandwidth of any potential side channel.
The capabilities of this daemon include:
**Basic connectivity tools**: Provides ping and traceroute to a remote endpoint.
**Network data capture**: Produces a PCAP file of data transiting the node’s external interfaces. Limited only to external interfaces to ensure that data within the trust boundary, such as over a loopback interface, cannot be captured.
**Stackshot**: Captures a backtrace of all processes on the system. Limited to only 1 stackshot per hour.
**CPU/Memory usage**: Collects statistics on what processes are using the most CPU, memory, or threads, for example.
[Security events](https://security.apple.com/documentation/private-cloud-compute/management#Security-events)
PCC nodes capture a limited number of security events through the securitymonitorlited daemon, which is a client of the EndpointSecurity framework. This daemon records the following security event types:
**Process Lifecycle**: ~[Process Exec](https://developer.apple.com/documentation/endpointsecurity/es_event_type_t/es_event_type_notify_exec?language=objc)~, ~[Process Exit](https://developer.apple.com/documentation/endpointsecurity/es_event_type_t/es_event_type_notify_exit?language=objc)~
**IOKit Usage**: ~[IOKit Open](https://developer.apple.com/documentation/endpointsecurity/es_event_type_t/es_event_type_notify_iokit_open?language=objc)~
**SSH**: ~[SSH Login](https://developer.apple.com/documentation/endpointsecurity/es_event_type_t/es_event_type_notify_openssh_login?language=objc)~/~[Logout](https://developer.apple.com/documentation/endpointsecurity/es_event_type_t/es_event_type_notify_openssh_logout?language=objc)~
**Network**: connection open (via the private NetworkStatistics framework)
**Note**
SSH is disabled on production PCC nodes, so while SSH events are included for completeness, they won’t fire in normal operation.
These events are exfiltrated via splunkloggingd, where the data is then analyzed in aggregate by Apple security teams to identify indicators of compromise.
The set of events that can be exported is filtered via the same mechanism that controls log-message filtering. The filter list is delivered with the PrivateCloudSupport cryptex and subject to our verifiable transparency guarantees. The event-capturing architecture prioritizes user privacy and deliberately doesn’t attempt to introspect or export data from within processes, instead preferring to capture metadata for the events.
[Network firewall](https://security.apple.com/documentation/private-cloud-compute/management#Network-firewall)
When a PCC node boots, darwin-init applies a pre-specified network policy that allows the node to obtain an IP address, download the necessary cryptexes, and personalize them. The PrivateCloudSupport cryptex contains the node’s firewall agent: denaliSE. This agent controls traffic ingress and egress between the PCC node and the rest of the Apple data center network and supports individual, stateful packet inspection with enforcement at layers 2, 3, and 4.
Once active, denaliSE communicates with the Denali control plane over mTLS, using a client certificate managed by the SEP. The control plane verifies the client’s identity and then computes a unique view of the Apple data center network security policy for access patterns that are specifically applicable to that node. Critically, this security policy only permits network access to and from the minimal data center services required to operate PCC. This computed policy is downloaded by denaliSE and enforced for all network traffic on the node.
denaliSE regularly publishes metrics about the health of the firewall and its enforcement actions for consumption by data center operators. Additionally, the BMC monitors the health of each PCC node’s denaliSE agent to ensure that it is operating normally.
### Anticipating Attacks
How PCC’s security and privacy mechanisms stand up to anticipated threats.
[Overview](https://security.apple.com/documentation/private-cloud-compute/attacks#overview)
The security and privacy design of Private Cloud Compute aims to guarantee that our five ~[core requirements](https://security.apple.com/documentation/private-cloud-compute/corerequirements)~ are never violated, even if the service were to be attacked.
To support this goal, we considered three principal threats and attack scenarios when evaluating the effectiveness of PCC’s security and privacy mechanisms.
**Accidental data disclosure**: Stateless computation requires that user data must never leave the trust boundary of a PCC node. But it must also be possible to observe and investigate issues within the service. Robust mechanisms need to be in place to ensure that observability metrics, logging, and other information that leaves a node cannot accidentally disclose user data.
**External compromise from a user request**: As with all Apple cloud services, Private Cloud Compute sets a high bar for security from external threats. While stateless computation presents a lower-risk target than other services that store user data, it’s important to ensure that user data remains confidential from even the most skilled attackers.
**Physical or internal access**: The premise of Private Cloud Compute is that user data must never be available to anyone other than the user, not even to Apple. Our threat model considers how an attacker with access to internal interfaces or systems might attempt to subvert or bypass PCC’s security mechanisms.
PCC has multiple layers of security for defense-in-depth protection, combining security mechanisms that prevent or hinder exploitation to help ensure that our core requirements withstand these scenarios. In this section, we examine each of these scenarios along with the security and privacy mechanisms we built into PCC that defend against such attacks. In addition, we look at how PCC’s transparency guarantees — one of the most unique aspects of PCC — allow external researchers to discover such an attack. We also recognize that further improvements may strengthen the security properties of PCC, so we include known limitations of the current system.
[Accidental disclosure](https://security.apple.com/documentation/private-cloud-compute/attacks#Accidental-disclosure)
PCC’s fundamental privacy goal is to perform ~[stateless computation](https://security.apple.com/documentation/private-cloud-compute/corerequirements#Stateless-computation-on-personal-user-data)~: user data is used exclusively to fulfill the user’s inference request and should not be accessible after request processing completes.
The PCC node is the trust boundary of PCC. If any data leak were to leak across this boundary, it would be a violation of our requirement for stateless computation, regardless of how the data is subsequently handled. Our transparency guarantees cover all code running within this boundary and allow security researchers to identify potential code paths that might inadvertently reveal user data. To consider the risk of accidental disclosure, we look at the ways data enters and leaves the trust boundary.
[Request encryption](https://security.apple.com/documentation/private-cloud-compute/attacks#Request-encryption)
Ensuring that user data is only exposed within our trust boundary starts with encrypting requests end-to-end between a user’s devices and the PCC nodes. PCC takes these steps to ensure that data is fully protected in transit:
The user’s device encrypts all requests end-to-end to a small number of specific PCC nodes. No intermediary services can access the request, and responses are encrypted back to the client using the same encrypted connection. For more information, see ~[Attested Request Handling](https://security.apple.com/documentation/private-cloud-compute/requesthandling)~.
PCC isolates processes that perform computation on user data from the processes that decrypt requests and encrypt responses. The processes aren’t exposed to the network, and sandbox rules prevent the processes from accidentally creating network connections. Apple auditors and security researchers can monitor sandbox profiles to identify changes in the processes that are exposed on the network. For more information, see ~[Request handling](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Request-handling)~.
Sometimes, user data must be transmitted between PCC nodes while processing a request, such as during ~[distributed inference](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Distributed-inference)~, where multiple PCC nodes work collaboratively to service a single request. User data is encrypted during transmission between nodes, but maintaining PCC’s transparency promises requires satisfying additional requirements beyond encrypting the data:
The software measurements of the destination PCC node must be identical to the software measurements that the client device verified and accepted.
The client device must be provided the hardware identity of the PCC nodes that will have access to the request.
~[Ensemble attestation](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Ensemble-attestation)~ enables these properties for distributed inference. The key negotiation process used in the ensemble ensures that all nodes share the same software measurements, and that the hardware identities of all ensemble members are included in the leader’s attestations. Using this negotiated key for exchanging user data ensures that the data is never exposed outside the set of trusted PCC nodes that are processing the request.
Even when network traffic is properly encrypted, traffic analysis attacks have long posed a risk to the privacy of user data. Research demonstrating effective attacks using ~[interactive user timings for SSH](https://www.usenix.org/conference/10th-usenix-security-symposium/timing-analysis-keystrokes-and-timing-attacks-ssh)~goes back decades, and more recently, analysis of packet sizes that reveal ~[token lengths](https://arxiv.org/abs/2403.09751)~ has effectively revealed content as well. The Inference Engine implements mitigations for the known token-length attack. Traffic analysis attacks are a dynamic field; if future research demonstrates additional traffic analysis attack opportunities, we will work to rapidly and systematically mitigate them in PCC.
[System observability](https://security.apple.com/documentation/private-cloud-compute/attacks#System-observability)
Effective operation of PCC requires PCC nodes to emit targeted, specific data about the runtime behavior of the system. This data includes custom, privacy-aware exporters for logs and metrics, using industry-standard protocols. The design of the PCC node goes to great lengths to ensure that observability data doesn’t become a vector for accidental disclosure of user data.
As discussed in ~[Management & Operations](https://security.apple.com/documentation/private-cloud-compute/management)~, the PCC node design centralizes the export of observability data into a small number of exit points: the forwarders for logs and metrics, and the agents that provide remote debug capabilities. These export mechanisms are designed to implement filtering on the data that they allow to leave the PCC node, and Apple has processes in place to ensure multistage review of all new data enabled by the filters.
Data filtering helps reduce the risk that user data may be accidentally exported as part of PCC’s observability tools, but it can’t completely eliminate the risk. It’s important to enable research and auditing of the data exposed by these tools to help ensure we can discover and remediate any issues quickly. When possible, PCC software releases include easily readable data files containing policy information used for data filtering. Making the policy information accessible allows Apple auditors and security researchers to inspect and analyze policy changes for issues. In addition to enabling offline analysis, the ~[Virtual Research Environment](https://security.apple.com/documentation/private-cloud-compute/virtualresearchenvironment)~ (VRE) allows security researchers to perform their own analysis of a running system, including ~[inspection of the diagnostic logging](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Inspect-diagnostic-logging)~ emitted from the node.
If user data were to be accidentally exposed, PCC’s data-handling policies go beyond industry best practices to protect the confidentiality of the data. The connections used to transmit observability data are protected by mutual TLS. Once observability data is collected, access is carefully managed, and data is maintained with a limited retention period.
Despite these steps, the accidental inclusion of user data in observability data remains a risk. For example, log data — which typically produces the largest amount of data per request — might contain unintended data at runtime, a simple traffic analysis might present a side-channel risk to encrypted network traffic, and a novel technique for extracting meaningful data from logging information might cause innocuous-seeming log lines to actually expose user data. For these reasons, Apple performs regular audits of the log data emitted by PCC nodes, encourages submission of reports based on analysis of log data in the VRE through the Apple Security Bounty, and endeavors to quickly resolve any issues discovered.
[User data isolation](https://security.apple.com/documentation/private-cloud-compute/attacks#User-data-isolation)
The PCC node is designed to limit unnecessary access to user data by managing the paths that user data might take. Key techniques that PCC uses to isolate user data, and thereby protect it from accidental exposure, include:
The PCC node software uses sandboxing, process isolation, and entitlements to enforce expectations about data flow. User data is handled in specifically designated processes with sandbox profiles designed to ensure that the processes only communicate with well-known services. These techniques simplify security analysis and help prevent user data from being disclosed accidentally to a process that doesn’t expect to handle user data.
PCC nodes run with ~[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)~, which ensures that any data accidentally written to the data volume can’t survive a reboot.
[External compromise](https://security.apple.com/documentation/private-cloud-compute/attacks#External-compromise)
Another significant threat our PCC security model considers is a potential compromise due to attacker-controlled inference requests. If PCC were to be compromised, this would allow attackers to exploit their access to access user data that is actively being processed on a compromised node. PCC’s security mechanisms aim to prevent initial compromise, detect it if it occurs, contain it to minimize the data and capabilities an attacker could acquire, limit the duration of the compromise, and diffuse attacks across the incoming requests.
[Preventing compromise](https://security.apple.com/documentation/private-cloud-compute/attacks#Preventing-compromise)
To help prevent a compromise of PCC node software, we take advantage of some of the same exploit-mitigation techniques that we use in iOS and macOS. These techniques include:
Enabling ~[Pointer Authentication Codes](https://support.apple.com/guide/security/operating-system-integrity-sec8b776536b/1/web/1#sec0167b469d)~ for all PCC code.
Using memory-safe Swift for code that performs initial processing of untrusted input.
Ensuring that external inputs are in structured data formats, such as Protobuf, to minimize the risk of parsing-related vulnerabilities.
Minimizing the attack surface by eliminating unnecessary components from the PCC node software.
[Detecting compromise](https://security.apple.com/documentation/private-cloud-compute/attacks#Detecting-compromise)
If a compromise occurs, we need to detect it quickly so we can stop and expel the attacker just as fast. While PCC’s privacy goals seemingly run counter to collecting the data typically used for detection techniques, the PCC node includes a ~[security event monitor](https://security.apple.com/documentation/private-cloud-compute/management#Security-events)~that reports limited security events in a privacy-safe way. Over time, we’ll continue to iterate on our detection techniques to improve efficacy and ensure they effectively prevent accidental disclosure of user data.
[Containing compromise](https://security.apple.com/documentation/private-cloud-compute/attacks#Containing-compromise)
If an attack is discovered that enables an attacker to establish an initial foothold on a PCC node, it’s crucial that the architecture of the PCC node prevents horizontal movement or privilege escalation, restricting the scope of the attack. The PCC node software achieves this restriction with the following techniques:
~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~ limits the processes an attacker can attempt to exploit as part of their exploit chain.
Process separation, in conjunction with privilege minimization and sandboxing, isolates any potentially compromised processes and limits the attack surface available to an attacker to prevent horizontal movement.
Network filtering rules, both ~[on-node](https://security.apple.com/documentation/private-cloud-compute/management#Network-firewall)~ and off-node, restrict outbound connectivity and prevent direct egress of user data.
SecureConfig ensures that nodes are ~[statically provisioned into ensembles](https://security.apple.com/documentation/private-cloud-compute/statelessinference#Ensemble-attestation)~. If a node is compromised while a member of one ensemble, it can’t be used to attack another ensemble’s data.
Minimization of the set of PCC nodes that can decrypt a request, ensuring an attacker must compromise a significant portion of the PCC fleet to access any particular request. For more information, see ~[Node selection](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-selection)~.
The strength of compromise containment is an area where further improvement is always possible, especially when it comes to policies like sandboxing. While the current sandbox profiles used in PCC significantly limit the attack surface exposed from each process, they are more coarse-grained in their access than those used by WebKit or ~[BlastDoor](https://support.apple.com/guide/security/blastdoor-for-messages-and-ids-secd3c881cee/web)~.
[Time-bounding compromise](https://security.apple.com/documentation/private-cloud-compute/attacks#Time-bounding-compromise)
In addition to containing the scope of a compromise, PCC ensures that any compromise is well-bounded in time, forcing attackers to continually and aggressively repeat their exploit of the system to maintain a foothold, which increases the likelihood of detection. Some of the techniques to time-bound a compromise include:
The use of a per-request process instance for ~[The Inference Engine](https://security.apple.com/documentation/private-cloud-compute/statelessinference#The-Inference-Engine)~’s initial request parsing and pre-processing, which forces attacks to migrate horizontally out of the process to persist beyond the lifetime of a particular request.
Periodic recycling of the tie-inferenced instances, which ensures that any attacker resident in a shared process containing user data is periodically evicted.
~[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)~, which limits compromise to a single boot session by ensuring that each boot resembles an erase install.
Note that the recycling behavior of tie-inferenced ensures that the data for completed requests is removed from the system in a well-bounded amount of time, rather than immediately wiped following every individual request. Within the bounds of the recycling behavior, certain aspects of data lifecycle depend on Swift memory management and the behavior of the system allocator.
[Diffusing compromise](https://security.apple.com/documentation/private-cloud-compute/attacks#Diffusing-compromise)
PCC’s core requirements include non-targetability to ensure that an attacker cannot target a particular user. Target diffusion significantly increases both the scale of compromise required and risk of detection of such an attack.
We designed PCC to enforce non-targetability across the entire request lifecycle through the use of the following:
Anonymous tokens for ~[authentication](https://security.apple.com/documentation/private-cloud-compute/requestflow#Client-authentication)~.
A third-party ~[anonymizing relay](https://security.apple.com/documentation/private-cloud-compute/requestflow#Network-transport)~ for submitting requests to PCC and accessing the PCC transparency log.
The transparency log to maintain key configuration, in addition to software releases.
Nevertheless, operational considerations may allow some bits of information about the client device to be visible outside the encrypted request:
To enable routing to nearby data centers, the client device’s rough geographical region is exposed by the local instance of the third-party relay in use.
To enable troubleshooting, the PCC client submits requests with headers containing basic, non-identifying information about the client device, such as the product (e.g. “iPhone”) and operating system build version.
Should a user of interest to an attacker be significantly distinguished by these properties, this information could potentially be used in a semi-targeted attack. Note that while the ~[fraud data protocol](https://security.apple.com/documentation/private-cloud-compute/requestflow#Fraud-data-protocol)~ can associate up to 8 bits of information with the anonymous Token Granting Token, this information is not exposed outside of the encrypted request.
If an attacker has the ability to intercept encrypted requests in transport, such as by compromising the PCC Gateway, then the strength of target diffusion is limited by the size of *k*, the number of ensembles that can decrypt each incoming request. The security implications of this value are discussed in ~[node selection](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-selection)~.
While target diffusion increases the necessary scale, and therefore risk of detection, of an attack, it doesn’t address the homogeneity of the PCC nodes. Because all PCC nodes run identical or very similar software, a software attack from request context on a single node could be exploitable at scale.
[Physical or internal access](https://security.apple.com/documentation/private-cloud-compute/attacks#Physical-or-internal-access)
PCC’s core requirements include that user data must never be available to anyone other than the user, not even to Apple staff, not even during active processing. As with any cloud service, the systems used by staff responsible for hardware and software development, the deployment and management of data centers, and the operational management of the service could be potential sources of a service compromise. Apple already has mature operational security practices, and for PCC we’re setting an even higher standard to support our enforceable guarantees: PCC’s design requires that even staff in one of these privileged positions can never have access to user data.
Protecting against insider access is a complex task. With the initial release of PCC, we believe that a single staff member could not access user data, even with authorized access to internal inputs that would typically be considered privileged and therefore restricted to a designated group. We evaluated more sophisticated attacks - employing intricate techniques and with higher acceptable attack costs - and believe these are highly unlikely to succeed and have a significant likelihood of detection.
[Privileged access to the data center](https://security.apple.com/documentation/private-cloud-compute/attacks#Privileged-access-to-the-data-center)
PCC’s transparency claims are rooted in ~[Hardware Integrity](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity)~. Despite our physical site controls, our threat model considers how an attacker with physical access to PCC nodes would attempt to directly exploit them to circumvent our ~[Secure Boot](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Secure-Boot)~ process or extract user data.
Whenever possible, hardware interfaces into the SoC are considered untrusted, including Apple’s privileged inputs used to manage the PCC fleet. Inputs are either strictly validated or covered within a node’s attestation, ensuring that the input is expected and published for inspection.
To prevent hardware modifications during manufacturing and assembly, we ~[image every chassis](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Hardware-lifecycle)~ as it is assembled and compare it against reference images. If any discrepancies are found, an investigation is triggered.
If the lid to a server chassis is opened, the PCC node powers off to make any and all user data inaccessible. The chassis attestation anti-replay value is immediately erased, invalidating the active chassis attestation measurements. Chassis attestations are freshly validated once per day. An invalid attestation means we quarantine the chassis and open a security investigation.
All Apple silicon designs undergo ~[extensive testing](https://www.independent.co.uk/tech/iphone-apple-security-software-lockdown-mode-b2450192.html)~, to identify and mitigate side-channel attacks. To prevent exploitation of an undisclosed hardware side-channel attack that could allow an attacker to recover information about in-flight requests, the PCC node implements anti-replay. This ensures the same request can’t be replayed multiple times to extract additional information.
[Privileged access to the PCC service](https://security.apple.com/documentation/private-cloud-compute/attacks#Privileged-access-to-the-PCC-service)
PCC node software is designed without privileged internal interfaces or capabilities: all interfaces that accept external input are treated as untrusted in PCC’s threat model. For example, there is no remote administrative shell, and ~[Ephemeral Data Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Ephemeral-Data-Mode)~ renders user data cryptographically inaccessible after a reboot, ensuring that if someone were to load or attempt to load non-production software on a PCC node after a power cycle, they cannot access user data.
Beyond the PCC node itself, it’s important to consider the potential impact of an attacker who gains control of other aspects of the PCC infrastructure. As discussed in ~[node selection](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Node-selection)~, the PCC Gateway plays a critical role in routing requests through the system. If an attacker were to attempt to gain control of the PCC Gateway and influence routing, the attacker could use this access in the following ways:
The PCC Gateway could issue the same request to multiple nodes as part of the exploitation of a side-channel attack, enabling them to partially bypass the anti-replay protections on each PCC node. However, PCC’s design ensures that only nodes with attestations validated by the client device can decrypt the request, limiting the scope of the attack to the set of up to *k* nodes provided by the client.
The PCC Gateway could bias the request routing toward a small number of nodes with compromised hardware. This is mitigated through target diffusion, as described in ~[diffusing compromise](https://security.apple.com/documentation/private-cloud-compute/attacks#Diffusing-compromise)~. This attack would be detectable in both our internal telemetry and in the Apple Intelligence reports generated by user devices.
Finally, an attacker with access to data center systems could attempt to provision fake or inauthentic hardware. To counter this concern, our ~[hardware provisioning ceremonies](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity#Certificate-ceremony-process)~ involve multiple parties who cross-check each step of the process, ensuring that a broad compromise of the process across multiple organizations at Apple would be required to bypass the controls.
[Compromised engineer credentials](https://security.apple.com/documentation/private-cloud-compute/attacks#Compromised-engineer-credentials)
The trustworthiness of PCC is built on ~[hardware attestation](https://security.apple.com/documentation/private-cloud-compute/hardwarerootoftrust)~. Modification of the hardware during design or manufacturing could jeopardize all transparency claims if the hardware security features that PCC relies on are compromised. The process of designing and validating silicon spans multiple years, and undergoes multiple sign-offs from several organizations within Apple. Any form of hardware backdoor would necessitate a long-term and wide-reaching compromise across Apple.
PCC’s hardware identity is based on keys that are provisioned and recorded during manufacturing solely through the SEP, during which it executes in a unique, attested mode. It is impossible for anyone to capture, derive, or control the key material used, even if the SEP were to be compromised. As discussed in ~[Hardware Integrity](https://security.apple.com/documentation/private-cloud-compute/hardwareintegrity)~, the process by which these keys are recorded and attested is managed by several organizations across Apple and observed by a third party.
Apple software engineers write the code that powers PCC. They use hardware-backed keys to sign their commits in Git repositories, and the source is then built and signed by Apple’s secure build system. The resulting binaries are included in the PCC transparency log for public inspection. The software supply chain process is the same as the process we use to build iOS and macOS and is designed to ensure the integrity of the full software lifecycle.
In addition to these protections, PCC’s verifiable transparency ensures that should an attacker compromise the software development process, the attack would produce immutable, observable artifacts that security researchers could analyze to detect the attack. To assist in this process, the ~[Virtual Research Environment](https://security.apple.com/documentation/private-cloud-compute/virtualresearchenvironment)~(VRE) includes tooling to make external verification of the log easier and more accessible.
The Virtual Research Environment loads the same user space images as we deploy into the production service, providing a very close approximation of the production service. The VRE makes inspectability similar to the ~[Security Research Device](https://security.apple.com/research-device/)~ to anyone, without the need to apply for a physical device.
To enable the PCC software to run under virtualization, the VRE is subject to some limitations:
The VRE operates with a paravirtualized GPU, using the host system’s graphics drivers and firmware.
The VRE uses a virtualized SEP. This enables a new capability for researchers — debugging and analyzing SEP code — but cannot invoke the real SEP functionality in silicon.
The VRE runs as a single inference node without distributed inference.
Due to these limitations, it is not possible to dynamically exercise every code path that runs in the production PCC service, requiring some manual inspection of the binaries.
To support analysis of the PCC binaries, we also publish portions of the PCC software source code, including many of the most critical PCC security mechanisms. We expect these tools to help researchers discover any implementation defect or unexpected code. However, this source does not include the capability for reproducible builds, so it is not possible to prove that the published PCC binaries are compiled from the published source code, limiting its use to that of an analysis aid.
[Conclusion](https://security.apple.com/documentation/private-cloud-compute/attacks#Conclusion)
To assess the strength of our implementation of PCC’s core security and privacy requirements, we’ve analyzed three primary threat and attack scenarios: accidental disclosure, external compromise, and attacks involving internal access. For each scenario, our analysis suggests that PCC’s current design is robust and includes multiple layers of defense-in-depth to withstand potential attacks. While there are opportunities for further hardening, PCC’s novel requirements also present a unique challenge: the risk of an unforeseen attack. We welcome reports of instances where PCC may not have satisfied our stringent security and privacy requirements, and we will work continuously to improve PCC and ensure we achieve them.

### Source Code
To simplify security research, source code is available for certain security-critical PCC components.
[GitHub Repository](https://github.com/apple/security-pcc)
[Overview](https://security.apple.com/documentation/private-cloud-compute/sourcecode#overview)
The source code in the ~[security-pcc](https://github.com/apple/security-pcc/)~ repository includes components of PCC that implement security mechanisms and apply privacy policies. We provide this code under a limited-use license agreement to allow researchers and interested individuals to independently verify PCC’s security and privacy characteristics and functionality.
The projects for which source code is available cover a range of PCC areas, including:
The ~[CloudAttestation](https://github.com/apple/security-pcc/tree/main/CloudAttestation/CloudAttestation)~ project, which is responsible for constructing and validating the PCC node’s attestations.
The ~[Thimble](https://github.com/apple/security-pcc/tree/main/Thimble)~ project, which includes the privatecloudcomputeddaemon that runs on a user’s device and uses CloudAttestation to enforce verifiable transparency.
The ~[splunkloggingd](https://github.com/apple/security-pcc/tree/main/darwinOSBits/splunkloggingd)~ daemon, which filters the logs that can be emitted from a PCC node to protect against accidental data disclosure.
The ~[srd_tools](https://github.com/apple/security-pcc/tree/main/srd_tools)~ project, which contains the VRE tooling and which you can use to understand how the VRE enables running the PCC code.




### Virtual Research Environment
Interact with and debug the PCC software stack.
[Overview](https://security.apple.com/documentation/private-cloud-compute/virtualresearchenvironment#overview)
The Private Cloud Compute Virtual Research Environment (PCC VRE) is a set of tools and images that can boot a version of PCC software and simulate a PCC node on a Mac with Apple silicon.
Beyond simply executing the production configuration of PCC, the VRE also enables researchers to load custom code or disable security features normally enforced by PCC’s attestations, so they can take a focused look at specific components of the PCC node.
A VRE instance virtualizes both the Application Processors and the Secure Enclave Processor (SEP), running minimally modified versions of system firmware to accommodate the differences between virtual and physical hardware.
Much like a physical PCC node, VRE provides the capability to generate SEP attestations and run inference requests. Security researchers can inspect and experiment with these code paths to get a deeper understanding of PCC’s components and how the system components handle user data.
[Facilitating PCC research](https://security.apple.com/documentation/private-cloud-compute/virtualresearchenvironment#Facilitating-PCC-research)
To facilitate research on the platform, the Virtual Research Environment provides a range of capabilities beyond simply running the PCC software in its stock configuration. These include the ability to:
Configure darwin-init to experiment with different Restricted Execution Mode states and software settings.
Load custom cryptexes that contain arbitrary code provisioned with arbitrary entitlements, including a shell.
Boot custom SPTM, TXM, and kernel cache firmware.
While the VRE allows researchers to inspect everything it contains, we encourage using it to identify potential vulnerabilities, such as the following:
Ways to execute unattested code, such as bypassing our code-signing and attestation mechanisms.
Exploitable flaws in request processing, which could potentially be used to leak user data.
Insufficient validation of system-configuration parameters, which could potentially be used to bypass our privacy protections.
Data-only attacks that abuse the non-transparent nature of codeless cryptexes.
Attack persistence techniques that survive reboots despite PCC’s use of an ephemeral data volume.
Any potential violations of our privacy protections, including through PCC’s diagnostic logging.
Note that the PCC inference engine supports operating in a distributed inference configuration, where multiple PCC nodes work together to complete a request. The code to support this mode is present in the PCC VRE. We encourage researchers to inspect it for security flaws, but operating in this mode is not currently supported by VRE tooling.
### Get Started with the VRE
Configure your system to run the PCC Virtual Research Environment (VRE).
[Overview](https://security.apple.com/documentation/private-cloud-compute/vresetup#overview)
The PCC Virtual Research Environment (VRE) requires a Mac with Apple silicon with at least 16GB of unified memory and macOS Sequoia 15.1 or later. For optimal VRE performance, we recommend using a Mac with at least 24GB of unified memory.
You can access PCC VRE tooling via the pccvre command-line tool, found under /System/Library/SecurityResearch/usr/bin in macOS. The instructions in this document assume your shell’s PATHincludes this directory. To add this location to PATH system-wide, you can run:
echo "/System/Library/SecurityResearch/usr/bin" | sudo tee /etc/paths.d/20-vre
You can use the pccvre command-line tool to create and manage VRE Virtual Machine (VM) instances; interact with instances to run custom research code; and understand and exercise the overall flow for making inference requests. pccvre and all of its subcommands display documentation when invoked with --help. You can configure shell completions for pccvre tool by following ~[ArgumentParser’s setup steps](https://apple.github.io/swift-argument-parser/documentation/argumentparser/installingcompletionscripts)~.
[Enable security research](https://security.apple.com/documentation/private-cloud-compute/vresetup#Enable-security-research)
Before using the VRE, you will need to configure your Mac to run security research virtual machines. This allows additional access to hardware features, which in turn might expose additional attack surface.
To enable research VMs, ~[boot into recoveryOS](https://support.apple.com/guide/mac-help/macos-recovery-a-mac-apple-silicon-mchl82829c17/mac)~, open Terminal, and invoke the following command:
csrutil allow-research-guests enable
You can validate this configuration from recoveryOS or a booted macOS environment using the following command:
csrutil allow-research-guests status
[Accept the PCC VRE license agreement](https://security.apple.com/documentation/private-cloud-compute/vresetup#Accept-the-PCC-VRE-license-agreement)
After you enable security research on your Mac and boot back into macOS, invoke the pccvre tool as the root user (using sudo) to view and accept the license agreement.
**Important**
You can use the Private Cloud Compute Virtual Research Environment and its tooling only for research as outlined in the license agreement. Commercial use is not permitted.
You can invoke pccvre license at any time to display and review the license agreement.
[Initial software assets](https://security.apple.com/documentation/private-cloud-compute/vresetup#Initial-software-assets)
You can use the pccvre tool to browse and download the assets associated with each PCC software release.
The VRE software assets include a demo model with a similar architecture to the Apple server-based Foundation model, scaled down for efficient execution in the VRE. The demo model has received language pre-training but has neither been trained for instruction following nor received any fine-tuning, so it’s expected to operate with unpredictable quality and can perform only text completion. The model also does not have safety features and might return results that are offensive or harmful. Accordingly, the model is provided on an as-is basis. Apple makes no other warranties, express or implied, and disclaims all implied warranties.
[Manage VRE instances](https://security.apple.com/documentation/private-cloud-compute/vresetup#Manage-VRE-instances)
You can create and manage VRE instances using the pccvre instance subcommand. A VRE instance represents a virtual machine along with its associated OS, ~[Cryptexes](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cryptexes)~, and configuration, including:
A cryptex that contains the private cloud extensions and ML stack (PrivateCloudSupport)
A cryptex that contains an LLM model
A darwin-init configuration that tells the Private Cloud Compute operating system where to fetch the cryptex assets and which software configuration (e.g. CFPreferences) to apply after boot
An HTTP server on the host to vend required assets, such as cryptexes, into the VM
Host-side tools to make inference calls to the VRE instance
[Create an instance](https://security.apple.com/documentation/private-cloud-compute/vresetup#Create-an-instance)
To create a new VRE instance, ~[select a PCC release](https://security.apple.com/documentation/private-cloud-compute/inspectingreleases#Exploring-available-releases)~, then download release assets, then invoke pccvre instance create:
$ pccvre release download <release-index>
...
Completed download of assets.
$ pccvre instance create -N <instance-name> --release <release-index>
pccvre instance create creates the associated VM, and then restores it with the Private Cloud Compute operating system. The VM then stays in a stopped state. VM instances are configured with four virtual CPUs, 14 GB of memory (paged), and a 64 GB “disk” (a sparse file that expands as it is populated).
[List instances](https://security.apple.com/documentation/private-cloud-compute/vresetup#List-instances)
To list the installed VRE instances, use the pccvre instance listcommand:
$ pccvre instance list
name                 status     ecid              ipaddr
vre                  running    758585c29e0fbe30  192.168.64.8
vre-test             shutdown   dd6ac0e7a7825f33  -
[Start an instance](https://security.apple.com/documentation/private-cloud-compute/vresetup#Start-an-instance)
To start a VRE instance, use pccvre instance start:
$ pccvre instance start -N <instance-name>
*
HTTP service started: 192.168.64.1:58386
Starting vre (ecid: 758585c29e0fbe30)
Started VM vre-835416c0
manifest_handoff_init: initialize region (size 0xc000)
image 0xb499ebf0: bdev 0xb49a6f80 type illb offset 0x20000 len 0x50545
image 0xb499eb50: bdev 0xb49a6f80 type logo offset 0x70545 len 0x665d
_nvram_load: loading nvram
_nvram_find_active_version: V1 provider
_nvram_find_active_version: V1 valid
...
In addition to starting the instance VM, instance start also starts the associated local HTTP server to vend cryptexes to the VRE instance. This HTTP server instance is started on the virtual bridge interface exposed to the VM and is not otherwise accessible outside the host. The lifetime of this HTTP server is tied to the lifetime of the instance — so when it’s stopped, the HTTP server is torn down.
The shell session where pccvre instance create is invoked displays the serial console I/O for the virtual machine hosting the instance until the instance is terminated. Use Ctrl-C to terminate the instance. You can use additional shell sessions to run commands and interact with the instance while it is running.
[Remove an instance](https://security.apple.com/documentation/private-cloud-compute/vresetup#Remove-an-instance)
To remove a VRE instance, use pccvre instance remove:
$ pccvre instance remove -N <instance-name>


Confirm deleting VRE 'vre' (y/n) y
[Configure instances](https://security.apple.com/documentation/private-cloud-compute/vresetup#Configure-instances)
The ~[darwin-init](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#darwin-init)~ binary runs shortly after boot on PCC nodes to fetch and apply a node’s configuration. In the VRE, it consumes a JSON-based configuration that is stored in the VM’s NVRAM and specifies the following:
Cryptexes to install on the node
Application preferences to set
Other system settings, such as logging privacy levels
You can use the pccvre instance configure command to inspect and manipulate this configuration. Note that configuration updates take effect only at boot time of the instance.
[Inspect and modify darwin-init configuration](https://security.apple.com/documentation/private-cloud-compute/vresetup#Inspect-and-modify-darwin-init-configuration)
For each release of Private Cloud Compute software, we provide a reference darwin-init configuration alongside the artifacts for bootstrapping the VRE. This configuration installs the associated private cloud extensions and demo model cryptexes, and configures the software on the VRE to accept local connections from the Private Cloud Tools.
You can inspect the darwin-init configuration using this command:
$  pccvre instance configure darwin-init dump -N <instance-name>
A similar command provides a new darwin-init configuration for an instance:
$ pccvre instance configure darwin-init set -N <instance-name> -I new_darwin_init.json 
[Enable SSH](https://security.apple.com/documentation/private-cloud-compute/vresetup#Enable-SSH)
The production PCC system doesn’t support shell access, but to enable SSH access for the VRE, we provide an additional Debug Shell cryptex that contains a shell and debugging tools. The pccvre instance configure ssh command adds this cryptex to the instance and updates the darwin-init configuration with the specified SSH public key:
pccvre instance configure ssh -N <instance-name> -p <ssh-public-key-path>
Use pccvre instance list to see the IP address that is assigned to the instance and then use ssh root@<IP>.
You can find additional debugging tools installed with the Debug Shell cryptex under /var/DarwinDataCenterSupportImage/.
[Inspect debug logging](https://security.apple.com/documentation/private-cloud-compute/vresetup#Inspect-debug-logging)
You can enable serial logging by restoring ~[research variant](https://security.apple.com/documentation/private-cloud-compute/vreresearchvariant)~ and setting serial=3 boot-arg using --boot-args argument of pccvre instance create.
You can also inspect system-wide log messages from ~[SSH](https://security.apple.com/documentation/private-cloud-compute/vresetup#Enable-SSH)~ using /var/DarwinDataCenterSupportImage/usr/bin/log provided by Debug Shell cryptex, which is equivalent to macOS log(1).
### Interact with the VRE
Issue requests to and configure the VRE.
[Issue inference requests](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Issue-inference-requests)
As part of the VRE tooling, we provide a wrapper that you can use to submit an inference request to the PCC software running inside the VRE. To issue an inference request, use the following command:
pccvre instance inference-request -N <instance-name> --prompt "<question>"
Behind the scenes, this command connects to the endpoint published by cloudboardd in the VRE — the same endpoint that the PCC Gateway uses to connect to PCC nodes in production. pccvre uses the underlying CloudBoard and TIE application protocols to submit a request and display the response.
inference-request command prints ~[the attestation bundle](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cloud-Attestation)~generated by the VRE instance, then tokens as they are streamed back from the VRE, and finally the request summary.
Executing inference:
{"sepAttestation":"MIIFGzCCBKICAQEwggJMohsEGWZlMDEtYjcwNmRhNzVlMzhjZDUyNy1kLTCjRw
...
tie_vre_cli.Apple_Cloudml_Inference_Tie_GenerateResponse:
next_token_response {
  token: "**\""
  token_padding: "M"
}
...
tie_vre_cli.Apple_Cloudml_Inference_Tie_GenerateResponse:
final_response {
...
[Inspect diagnostic logging](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Inspect-diagnostic-logging)
There are five types of data that can leave PCC nodes: logs, crash reports, panic reports, security events, and metrics.
You can configure the VRE to forward this diagnostic data to a local collector, using the darwin-init configurations provided below. In these examples, <ip> is the IP address and port of your collector.
[Enable log, crash, and panic forwarding](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Enable-log-crash-and-panic-forwarding)
"secure-config": {
  "com.apple.logging.policyPath": "/private/var/PrivateCloudSupport/opt/audit-lists/customer/",
  "com.apple.logging.logFilteringEnforced": true,
  "com.apple.logging.crashRedactionEnabled": true
},
"preferences": [
  {
    "key": "Predicates",
    "value": [
      "process == \"cloudboardd\""
    ],
    "application_id": "com.apple.prcos.splunkloggingd"
  },
  {
    "key": "Index",
    "value": "<index name>",
    "application_id": "com.apple.prcos.splunkloggingd"
  },
  {
    "key": "Server",
    "value": "http://<ip>:8088",
    "application_id": "com.apple.prcos.splunkloggingd"
  },
  {
    "key": "Token", // optional
    "value": "<token val>",
    "application_id": "com.apple.prcos.splunkloggingd"
  }
]
The above configuration instructs splunkloggingd in the VRE to forward crash logs, panic logs, and allow-listed log lines that match the provided predicate.
Additionally, please note:
Predicates: Replace foobar with the process of interest. You can use an “always true” predicate such as "foo" == "foo" to forward all allowed logs. See man log for more help with predicates.
Token: Optional key. If your collector requires a token, include it here to have it piped through to the log forwarder.
Index. Required. If your collector requires an index (such as Splunk), put the index here. If not, then put any string value.
[Enable security events](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Enable-security-events)
"secure-config": {
  "com.apple.securitymonitorlited.serverURL" : "http://<ip>:8088"
}
The above configuration overrides the destination for security events. Note that this setting is not respected when the secure-config security policy is set to customer.
[Enable metrics submission](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Enable-metrics-submission)
{
  "application_id" : "com.apple.acdc.cloudmetricsd",
  "key" : "DefaultDestination",
  "value" : {
    "Namespace" : "namespace",
    "Workspace" : "workspace"
  }
},
{
  "application_id" : "com.apple.acdc.cloudmetricsd",
  "key" : "Destinations",
  "value" : [
    {
      "Clients" : [
      ],
      "Namespace" : "namespace",
      "PublishInterval" : 60,
      "Workspace" : "workspace"
    }
  ]
},
{
  "application_id" : "com.apple.acdc.cloudmetricsd",
  "key" : "OpenTelemetryEndpoint",
  "value" : {
    "DisableMtls" : true,
    "Hostname" : "<ip>",
    "Port" : <port>
  }
},
{
  "application_id" : "com.apple.acdc.cloudmetricsd",
  "key" : "UseOpenTelemetryBackend",
  "value" : true
},
{
  "application_id" : "com.apple.acdc.cloudmetricsd",
  "key" : "LocalCertificateConfig",
  "value" : { }
}
The above configuration enables cloudmetricsd to submit metrics data to the provided host and port.
[Configure a collector](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Configure-a-collector)
Logs, crash reports, panic reports, and security events are all forwarded using the Splunk HEC protocol. You can configure any collector that supports this protocol — such as Splunk, ~[Vector](https://vector.dev/)~, or ~[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)~ — to receive and display these events. Metrics are forwarded using ~[Open Telemetry Line Protocol \(OTLP\)](https://opentelemetry.io/docs/specs/otlp/)~ and require a collector that can accept OTLP events.
Using the OpenTelemetry Collector’s splunk-hec module can enable receiving events sent via both the OTLP and Splunk HEC protocols. To use this module to receive events from the VRE, start by downloading otelcol-contrib from a release of ~[opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-releases/releases)~.
Then construct a configuration (otel.yaml) as follows:
receivers:
  splunk_hec:
    endpoint: "0.0.0.0:8088"
    access_token_passthrough: true
  otlp:
    protocols:
      grpc:
        endpoint: "0.0.0.0:8089"


processors:


exporters:
  debug:
    verbosity: normal


service:
  pipelines:
    logs:
      receivers: [splunk_hec]
      exporters: [debug]
    metrics:
      receivers: [otlp]
      processors: []
      exporters: [debug]
This configuration enables receiving all of the types of diagnostic data listed above. You can find more details on configuring the output of the ~[debug exporter](https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/debugexporter/README.md)~ and ~[splunkhecreceiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/splunkhecreceiver)~ at their respective repositories.
You can then launch the collector as follows:
./otelcol-contrib --config otel.yaml
If you configured the VRE instance to emit diagnostics, events print out to stdout.
[Inspect an attestation bundle](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Inspect-an-attestation-bundle)
You can inspect ~[attestation bundles](https://security.apple.com/documentation/private-cloud-compute/softwarelayering#Cloud-Attestation)~ of PCC production nodes, as well as VRE instances. Use the ~[Apple Intelligence Report](https://security.apple.com/documentation/private-cloud-compute/appendix_appleintelligencereport)~ to view attestations of PCC production nodes. ~[Issue an inference request](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Issue-inference-requests)~against a VRE instance to view its attestation bundle.
Use pccvre attestation canonicalize to generate a ~[release structure](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Release-data-structure)~ from an attestation bundle. Note that releases generated using the VRE will not match PCC node releases due to differences in SoC identifiers, virtualized kexts, and demo model. Use pccvre attestation canonicalize --detail and pccvre release dump --detail to print ~[Image4 manifests](https://security.apple.com/documentation/private-cloud-compute/appendix_secureboot)~ of tickets in a release structure and compare releases.
Use pccvre attestation verify to verify an attestation using the host’s CloudAttestation framework. For VRE attestations to be successfully verified, the following flags must be set:
--no-strict-certificate-validation because VRE instances are not provisioned with DCIK certificates.
--no-transparency-proof-validation because VRE releases are not published to the transparency log and do not match PCC node releases due to differences in SoC identifiers, virtualized kexts, and demo model.
--no-ensemble-topology-validation because VRE instances are not configured in an ensemble configuration.
[Load custom cryptexes](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Load-custom-cryptexes)
Use cryptexes to create and package additional software to install on a VRE instance.
The pccvre tool provides a command to create a new cryptex from a specified directory structure:
$ pccvre cryptex create —source CustomCryptexRootDirectory —variant MyCustomCryptex
Created new cryptex at path: MyCustomCryptex.aar with variant name: MyCustomCryptex
When such a cryptex is installed in VRE, its content is mounted at /private/var/PrivateCloudSupportInternalAdditions/. pccvre cryptex create marks packaged binaries as allowed in ~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~.
Binaries installed with a custom cryptex must have a code signature; ad-hoc signing is sufficient. Cryptex variant is an identifier string that must be unique within a VRE instance.
pccvre provides helpers to easily list and modify the set of cryptexes configured for a VRE instance:
$ pccvre instance configure cryptex list -N <instance-name>
Configured cryptexes:
- FM_LANGUAGE_SECURITY_RESEARCH_V1
- PrivateCloud Support
$ pccvre instance configure cryptex remove -N <instance-name> -V PrivateCloudSupport
Removed cryptex matching 'PrivateCloudSupport' from VRE instance.
$ pccvre instance configure cryptex list -N vre
Configured cryptexes:
- FM_LANGUAGE_SECURITY_RESEARCH_V1
$ pccvre instance configure cryptex add -N <instance-name> -C "MyCustomCryptex:$PATH_TO_MY_CUSTOM_CRYPTEX"
Added cryptex 'MyCustomCryptex' to VRE instance.
[Execute binaries in a cryptex](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Execute-binaries-in-a-cryptex)
The executables present in a cryptex may link libraries and frameworks also present in the cryptex. To enable dyld to find these libraries and frameworks, you must run the executable with the cryptexctl exec command to set an appropriate subsystem_root_path value that informs dyld of the relevant search paths:
cryptexctl exec /private/var/PrivateCloudSupportInternalAdditions/ /private/var/PrivateCloudSupportInternalAdditions/$PATH_TO_EXECUTABLE
In this example, the binary at $PATH_TO_EXECUTABLE is able to link libraries and frameworks located relative to /private/var/PrivateCloudSupportInternalAdditions/. Any children of that process automatically inherit the configuration. This step is needed only when running such executables manually, such as through ssh, as cryptexd automatically handles it when loading LaunchDaemons contained within a cryptex.
[Disable Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Disable-Restricted-Execution-Mode)
~[Restricted Execution Mode](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Restricted-Execution-Mode)~ (REM) enables the system to lock out functionality that’s required only during the system’s initial boot and setup. Entering REM is enforced by TXM to be a one-way transition switch, after which the TXM refuses to load additional trust caches and imposes new constraints on code execution.
By default, the darwin-init configuration for the VRE configures REM the same way as actual PCC nodes — {"userspace-reboot": "rem"}. After setup is complete, darwin-init initiates a user-space reboot, and launchd makes a system call to request TXM to activate the one-way REM switch. This process limits the set of executables that can run after entering REM to only those that are allow-listed based on loaded trust caches.
On the VRE, you can change the darwin-init configuration to {"userspace-reboot": "rem-dev"}. This change configures the VRE to forgo making a system call to TXM to activate the one-way REM switch after the user-space reboot, which allows you to use tools that are normally restricted by REM.
[Debug the kernel](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Debug-the-kernel)
You can debug the kernel by attaching to the GDB stub of a VRE instance. pccvre instance start prints the GDB stub port:
$ pccvre instance start --name vre
...
GDB stub available at localhost:59013
[Restore custom firmware](https://security.apple.com/documentation/private-cloud-compute/vreinteraction#Restore-custom-firmware)
The PCC VRE supports restoring an instance with custom firmware for the kernel cache, SPTM, and TXM images. To see further documentation for these options, invoke pccvre instance create --help.
All system firmware is packed as an Image4 payload (.im4p) file. The pccvre image4 extract command provides the functionality to extract binary payloads from the Image4 file. Conversely, the pccvre image4 package command provides the functionality to package a binary payload into an image4 wrapped payload for the specified firmware. To see further documentation for these commands, invoke pccvre image4 --help.

### Research Variant
Use the research variant to dive deeper into PCC.
[Overview](https://security.apple.com/documentation/private-cloud-compute/vreresearchvariant#overview)
By default, pccvre restores new VRE instances with a “customer” variant of the operating system. We also provide a “research” variant that enables functionality specific to dynamic analysis of the system.
To restore the research variant of the Private Cloud Compute operating system, use pccvre instance create --variant research.
There are three VRE firmware images that relax security policy under the research variant:
iBoot: relaxes constraints on NVRAM variables, such as boot-args.
Kernel cache: relaxes constraints on DYLD environment policy, such as allowing DYLD_INSERT_LIBRARIES.
Trusted Execution Monitor: relaxes constraints on debugging policy, allowing debuggers using the research.com.apple.license-to-operate entitlement.
[iBoot](https://security.apple.com/documentation/private-cloud-compute/vreresearchvariant#iBoot)
iBoot implements a security policy that sanitizes the boot-args that are passed to the kernel. On research builds, iBoot does not enforce this sanitization when it provides the boot-args data kept within NVRAM to the kernel. As a result, any boot-args that are parsed by the research kernel are respected on the system (some security-sensitive boot-args are not parsed on non-development-style builds of the kernel).
For example, the serial=3 argument instructs the kernel to output serial logging to the console. This is an argument that is parsed by the research kernel, which allows you to obtain rich serial logs from the system kernel.
[Kernel cache](https://security.apple.com/documentation/private-cloud-compute/vreresearchvariant#Kernel-cache)
As a process starts running, the dynamic linker is the first component that runs code within the process. The dynamic linker resolves all linkages for dynamic libraries within the process and then jumps to the application’s main() function.
There are certain environment variables that you can pass to an application, which can affect the behavior of the dynamic linker. For example, use the DYLD_INSERT_LIBRARIES environment variable to pre-inject a custom dynamic library into a process. Given the security-sensitive nature of such an operation, the dynamic linker consults with the kernel to determine whether such environment variables are allowed. The research kernel cache relaxes security enforcement for this policy and allows you to pass these environment variables to all kinds of applications and processes on the system.
Pre-injecting a custom dynamic library can interpose on library code within a process, which allows you to run code with the same privileges as the target process.
[Trusted Execution Monitor](https://security.apple.com/documentation/private-cloud-compute/vreresearchvariant#Trusted-Execution-Monitor)
Trusted Execution Monitor (TXM) is the monitor layer that enforces all execution policy on the system. On PCC nodes, TXM unconditionally disables ~[Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)~ to prevent modification of system runtime behavior. On the research variant, TXM keeps Developer Mode — and debug functionality — enabled for user-space code.
PCC is built on the security foundations of iOS. Enabling Developer Mode on iOS is only *one* of the requirements to debug an application. To allow code modification, an application must mark itself as *debuggable* by claiming the get-task-allow entitlement. This ensures that even in Developer Mode, you can debug only development applications, and system binaries such as launchdremain off-limits.
On the research variant, TXM allows the use of the research.com.apple.license-to-operate entitlement. This special entitlement is bestowed upon a *debugger*, instead of a *debuggee*, and allows the debugger to mark any target application as debuggable. This allows you to perform dynamic analysis of any process on the system.


### Documentation
**[Exploring available releases](https://security.apple.com/documentation/private-cloud-compute/inspectingreleases#Exploring-available-releases)**
You can inspect published releases of the Private Cloud Compute component directly from the live transparency log using the pccvre releasecommand:
$ pccvre release list
Found 10 releases:


    1245: b4a30eb9b838f4387a657be219b71c59e79451963f5da714118721163fd62b30
...
By default, the 10 most recent release entries are displayed, each as a release index followed by a (SHA256) digest of the aggregate manifest tickets that make up the components. There are additional types of entries in the transparency log that are not listed by this command, and account for gaps in the index numbers (for example, key bundles and “liveness” checks used by operations).
Use the --detail argument to view additional details for each release. This displays the individual digests for the OS manifest ticket along with the associated cryptexes for the release (such as Private cloud extensions). Note that the software components are published while the model/adapter images will not be.
Found 10 releases:


```
    576: 641b922d4e6eb7202506b68c891a4d33247b4ab3795812e5a5dbd7a97d39bca1
         [expires: 2024-10-22T15:56:20]
         [created: 2024-10-02T15:36:17]
    Tickets
          OS: 9b297c72bfe277bf5acc50d97cd123714d96b4698ee659d6f0ad97516f06be3c
      Cryptexes
        Code: 9b649163ed720d52722e0d2e3619093eb390e83f9a6c046efc029109a55bf28f
        Data: 6ee13427a6fab61e563111978820ab57178d3098cec4ebe5a931e4b4177af8d3
        Data: 2ec9158ac273737a474d108c47a7d7cdbd0ae77d93070ca53b406e8577cc5aff
        Data: cc7e34d648de5212f23cc2d3dfb2054c89436cc2398b7b784752f1ace02d8d48
        Data: ae16dcd6c3424a5305b6867788a5b9994ca8d936510d421994e4dd80e8eca774


...
```
The --count and --start/--end arguments can be used to select ranges (by index number) and the number of past releases.
**[Downloading available releases](https://security.apple.com/documentation/private-cloud-compute/inspectingreleases#Downloading-available-releases)**
You can download a release either by index number or its associated digest using the following command:
$ pccvre release download [--overwrite] <index | sha256>
Software cryptexes are downloaded into a cached folder along with a demo model for research purposes. It is not possible to download specific cryptexes; however, existing assets already downloaded (e.g., demo model) will normally be skipped (the --overwrite argument will download and update existing assets to the cache).
**[Auditing the transparency log](https://security.apple.com/documentation/private-cloud-compute/inspectingreleases#Auditing-the-transparency-log)**
You can audit the correctness of the PCC transparency log with the transparency-logsubcommand:
```
$ pccvre transparency-log audit --continuous
Top Level Tree: (466098/466098)
	Valid root digest: a77c032ca697ceb467a78a2a71a784f44dc84a86c325a70b465c33323ff4fc41 ✅
Per Application Tree: (30805/30805)
	Valid root digest: 3cf1cdaf4a1414cd7246b66372d5aa413b7d6ffe987194abb06b14809710b452 ✅
Application Tree: (37845/37845)
	Valid root digest: ba94e99d4b6b64d001c6bc4f68f90ebf1026261797ec5a394111f6cc5c15d4ec ✅
waiting 30s until next update
```


All downloaded leaves are stored as JSON files under ~/Library/Application Support/com.apple.security-research.pccvre/transparency-log/<environment>:
```
$ ls ~/Library/Application\ Support/com.apple.security-research.pccvre/transparency-log/production
applicationTree.json
perApplicationTree.json
topLevelTree.json
```
Subsequent invocations of the transparency-log subcommand will resume verification from the previously downloaded leaves.
**[Verifying an attestation’s inclusion proof](https://security.apple.com/documentation/private-cloud-compute/inspectingreleases#Verifying-an-attestations-inclusion-proof)**
Attestations contain a Merkle inclusion proof for the [Release](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Release-data-structure) currently running on the PCC node in the form of a [LogEntry protobuf structure](https://security.apple.com/documentation/private-cloud-compute/appendix_transparencylog#Log-server-protocol), which contains several key fields of data that can be used to verify the inclusion proof against a locally constructed view of the transparency log:
SignedLogHead, which contains both the revision number and leaf count of the transparency log used to generate the inclusion proof.
hashesOfPeersInPathToRoot, which contains an array of peer hashes needed to reconstruct the Merkle root hash.
nodePosition, which indicates the index of the leaf node for which the inclusion proof is generated.
With all of these items, you can use the information received from the SignedLogHead to slice a local copy of the transparency log from 0..<logSize. This constructs a view of the transparency log just as it was when the server created the inclusion proof.
The Merkle root hash of this sliced view of the log will match the root hash from computing the root hash from hashesOfPeersInPathToRoot and nodePosition. For more details on how Merkle inclusion proofs work, see [Section 2.1.3 of Certificate Transparency](https://datatracker.ietf.org/doc/html/rfc9162#merkle_inclusion_proof).
Assuming you already have a verified and up-to-date local copy of the transparency log from the pccvre transparency-log audit command, you can use the pccvre transparency-log verify-inclusion command to verify a specific attestation from an [Apple Intelligence Report](https://security.apple.com/documentation/private-cloud-compute/appendix_appleintelligencereport):
```
$ pccvre transparency-log verify-inclusion 
   --request-index <request-index> 
   --attestation-index <attestation-index> 
   <path to Apple_Intelligence_Report.json>
```
Since an Apple Intelligence Report contains many requests, each containing many attestations, you must provide both the request index and the attestation index for a given request. For example, to verify the first attestation of the first request:
```
$ pccvre transparency-log verify-inclusion
   --request-index=0
   --attestation-index=0
   ~/Downloads/Apple_Intelligence_Report.json
   
Successfully verified inclusion proof ✅ (revision: 28524, index: 34946, logSize: 35254, rootDigest: 2112b3b1ce1be4ff01b72e95872abc43c588132c1aa3db32a6d8960dd1f57d24)
```


### Appendix: System Configuration
The node’s configuration parameters.
[Overview](https://security.apple.com/documentation/private-cloud-compute/appendix_systemconfig#overview)
The darwin-init process implements a policy to limit which configuration it will apply in customer security mode. We summarize the current policies here for reference and illustrative purposes, but the authoritative policy is as implemented in darwin-init.
For the top-level keys, darwin-init prohibits any configuration which is not in accordance with the policy described here. Any key not listed is disallowed.
| **Top-Level Key**                             | **Policy**                                                   |
|-----------------------------------------------|--------------------------------------------------------------|
| `ca-roots`                                    | Allow Apple’s internal Certificate Authority to be Trusted.  |
| `cryptex`                                     | Allow cryptexes to be installed.                             |
| `firewall`                                    | Allow firewall rules to be installed at boot.                |
| `preferences`                                 | Setting CFPrefs is allowed only for the application IDs listed below. |
| `result`                                      | failureAction must be set to reboot or exit.                 |
| `log: system-log-privacy-level`               | Private logs must be redacted by setting system-log-privacy-level to "Public". |
| `log: system-logging-enabled`                 | Logging to disk and snapshots must be disabled by setting system-logging-enabled to false. |
| `narrative-identities`                        | Allow any setting.                                           |
| `logtext`                                     | Allow any setting.                                           |
| `computer-name, host-name, local-host-name`   | Allow configuring hostname.                                  |
| `perfdata`                                    | Allow emitting boot performance data.                        |
| `issue-dcrt`                                  | Allow any setting.                                           |
| `ssh`                                         | Enabling ssh daemon not permitted. Must be unset or false.   |
| `reboot`                                      | System reboot after set up not permitted. Must be unset or false. |
| `userspace-reboot`                            | Opting out of userspace-reboot into rem not permitted. Must be "rem" or unset. |
| `diagnostics-submission-enabled`              | Enabling diagnostic log submission not permitted. Must be unset or false. |
| `lock-cryptexes`                              | Disabling cryptex lockdown not permitted. Must be true or unset. |
| `cryptex-download-bandwidth-limit`            | Allow configuring bandwidth used for cryptex downloads.      |
| `secure-config`                               | See table below for policy.                                  |
| `usage-label`                                 | Allow any setting.                                           |
| `retain-previously-cached-cryptexes-unsafely` | Retaining cryptexes from previous boot session configs not permitted. Must be unset or false. |
| `apply-timeout`                               | Allow any setting.                                           |
| `user`                                        | Creating and configuring users not permitted.                |
| `network`                                     | Applying custom network configuration not permitted.         |
The customer policy enforces the following restrictions on secure-config keys:
| **Key** | **Required Value** | **Purpose** |
|---|---|---|
| com.apple.logging.crashRedactionEnabled | true | Redacts unique information from crash reports generated on the node. |
| com.apple.logging.logFilteringEnforced | true | Enforces aggressive filtering of the unified logging store (cf. os_log(3)). |
| com.apple.logging.metricsFilteringEnforced | true | Enables only a limited subset of metrics from the node. |
| com.apple.logging.policyPath | /private/var/PrivateCloudSupport/opt/audit-lists/customer/ | Filesystem path to the log policy directory. |
| com.apple.pcc.research.disableAppleInfrastrucutureEnforcement | Unset or false on hardware, any value in VRE | Relaxes validation of PCC infrastructure external to the node, for example certificates of the PCC Gateway. |
| com.apple.tie.allowNonProdExceptionOptions | Unset or false | Relaxes validation of external inputs in TIE, for example prompt template enforcement. |
| com.apple.CloudAttestation.routingHint | Any value | Indicates the routing hint clients need to pass to route to this node. Included in attestation. |
| com.apple.CloudAttestation.ensembleMembers | Any value | Indicates other members of the ensemble. Included in attestation. |
The customer policy allows setting preferences in the following CFPrefs domains:
| **Domain** | **Purpose** |
|---|---|
| com.apple.acdc.cloudmetricsd | Configures the cloudmetricsddaemon for metrics submission via OpenTelemetry Protocol. |
| com.apple.acsi.cloudusagetrackingd | Specifies a project identifier associated with the node for inclusion in cloudmetricsreporting. |
| com.apple.cloudos.AppleComputeEnsembler | Defines ensemble properties, such as hostname and identifier for each node. |
| com.apple.cloudos.cb_attestationd | Configures the cb_attestationddaemon, e.g. retry and backoff behavior for attestation generation. |
| com.apple.cloudos.cb_configurationd | Configures the cb_configurationddaemon, e.g. the endpoint for the ~[Runtime configurable properties](https://security.apple.com/documentation/private-cloud-compute/requesthandling#Runtime-configurable-properties)~service. |
| com.apple.cloudos.cb_jobauthd | Configures the cb_jobauthd daemon, e.g. the endpoint used to retrieve the TGT signing key. |
| com.apple.cloudos.cb_jobhelper | Configures the cb_jobhelper instances, e.g. TGT validation enforcement. |
| com.apple.cloudos.cloudOSInfo | Configures the CloudOSInfo framework used to obtain node OS version and release specifications. |
| com.apple.cloudos.cloudboardd | Configures the cloudboardd daemon, the central request coordinator, e.g. health service and RemoteServiceDiscovery endpoints. |
| com.apple.cloudos.CloudBoardNullApp | Configures the NullCloudApp flow for validating that the Private Cloud Compute service is running. |
| com.apple.cloudos.NullCloudController | Configures the NullCloudApp controller to inform cloudboarddabout the current Private Cloud Compute workload. |
| com.apple.cloudos.hotproperties.cb_jobhelper | Configures cb_jobhelper hot properties, e.g. request message size limit to prevent jetsam during an attack. |
| com.apple.cloudos.hotproperties.cloudboardd | Configures cloudboardd daemon hot properties, e.g. timeout for idle connections to client devices. |
| com.apple.cloudos.hotproperties.test | Configures tests for the hot properties service. |
| com.apple.cloudos.hotproperties.tie | Configures TIE Inference Enginehot properties, e.g. deny lists to apply to incoming request prompts. |
| com.apple.prcos.splunkloggingd | Configures the splunkloggingddaemon, e.g. predicates for filtering logs to exfiltrate to Splunk. |
| com.apple.privateCloudCompute | Specifications for the CloudAttestationframework, e.g. environment in which the node is running |
### Appendix: Secure Boot Tags
The format of an Image4 manifest.
[Overview](https://security.apple.com/documentation/private-cloud-compute/appendix_secureboot#overview)
Objects used in the APTicket include:
| **Boot Firmware** | **Four Character Code** | **Activator** | **Executable Code** | **Purpose** |
|---|---|---|---|---|
| Apple Converged IO | ciof |  | Yes | CIO image |
| Apple Neural Engine | ane1 |  | Yes | ANE image |
| Apple Neural Engine | anef |  | Yes | ANE image |
| Device Tree | dtre | iBoot |  | Device tree that is patched by iBoot and handed forward to the kernel |
| FDR Trusted Root CA for AP | ftap |  | No | Hash of FDR Trusted Root CA, used for the AP |
| FDR Trusted Root CA for SEP | ftsp |  | No | Hash of FDR Trusted Root CA, used for the SEP |
| Graphics | gfxf |  | Yes | GPU firmware |
| Kernel Cache | krnl | iBoot |  | The kernel image, including all extensions |
| Local Storage iBoot | illb | Secure ROM |  | The iBoot booted by Secure ROM during a normal boot |
| NAND Services | ansf | iBoot |  | Basic NAND support |
| OS Image | rosi | Restore OS |  | The OS image which is restored to the system volume |
| Power Management services | pmpf |  | Yes | Power Management Processor |
| Restore ANE | ran1 |  | Yes | ANE image which boots in restore OS |
| Restore Converged IO | rcio |  | Yes | Basic CIO support in restore OS |
| Restore FDR Trusted Root CA for AP | rfta |  | No | Hash of Restore FDR Trusted Root CA, used for the AP |
| Restore FDR Trusted Root CA for SEP | rfts |  | No | Hash of Restore FDR Trusted Root CA, used for the SEP |
| Restore Kernel Cache | rkrn | iBoot |  | The kernel image which boots in the restore OS |
| Restore NAND Services | rans |  |  | Basic NAND support in restore OS |
| Restore RAM Disk | rdsk |  |  | The operating system RAM disk that boots in the restore OS |
| Restore Secure Page Table Monitor | rspt |  |  | The SPTM image which boots in the restore OS |
| Restore TMU | rtmu |  | Yes | TMU image used in restore OS. See tmuf. |
| Restore Trust Cache | rdtr | iBoot |  | The trust cache covering the contents of the Restore RAM Disk |
| Restore Trust Cache | rtsc |  | No | The trust cache covering the contents of the restore OS |
| Restore Trusted Execution Monitor | rtrx |  |  | The TXM image which boots in the restore OS |
| Restore sepOS | rsep |  |  | The sepOS which boots in the restore OS |
| Secure Page Table Monitor | sptm |  |  | The SPTM image |
| Smart IO | siof |  | Yes |  |
| System Volume Sealing Metadata | msys | Restore OS |  | Metadata describing the normal form of the filesystem. Applied prior to sealing. |
| System Volume Seal | isys | iBoot |  | Root of hash tree covering the system volume |
| Time Management Unit | tmuf |  | Yes | TMU image. Synchronizes time across Thunderbolt (and USB4) links. |
| Static Trust Cache | trst | iBoot | No | The trust cache covering the contents of the OS Image |
| Trusted Execution Monitor | trxm | iBoot |  | The TXM image |
| USB Recovery iBoot | ibec | Secure ROM |  | The iBoot downloaded via USB and booted during recovery scenarios |
| iBoot Data | ibdt | iBoot |  | iBoot tunables that can be revised independently of iBoot itself |
| iBoot Second Stage | ibss | Secure ROM |  | The iBoot booted by Secure ROM during DFU |
| iBoot | ibot | Secure ROM |  |  |
| sepOS | sepi |  |  | sepOS |
Cryptexses use an additional set of objects:
| **Component** | **Four Character Code** | **Use** | **Activator** | **Action** |
|---|---|---|---|---|
| Info.plist | ginf | Metadata about the cryptex | cryptexd | Reserves cryptex identifier. May specify custom mount point |
| Disk Image | gdmg | The cryptex disk image | cryptexd | Excluded from the cryptex ticket, disk image integrity is protected by gtgv |
| Seal | gtgv | The root of the filesystem’s hash tree | APFS filesystem driver | Pins root hash to filesystem hash tree |
| Trust Cache | gtcd | The code directory hashes of all executable content | ~[Trusted Execution Monitor](https://security.apple.com/documentation/private-cloud-compute/softwarefoundations#Code-Signing)~ | Permits listed cdhashes to execute |
For additional information about trust cache objects, see ~[Appendix: Trust Cache Format](https://security.apple.com/documentation/private-cloud-compute/appendix_trustcache)~.
An Image4 manifest can specify the following constraints:
| **Constraint** | **Four Character Code** | **Purpose** |
|---|---|---|
| Chip ID | chip | Identifies a specific SoC |
| Security Domain | sdom | Security policy domain of the SoC |
| Board ID | bord | Identifies a specific product, within the scope of the Chip ID and Security Domain |
| Unique Chip ID | ecid | Unique value assigned to each individual SoC, within the scope of a specific Chip ID |
| Unique Device ID | udid | Combination of Chip ID and ECID, providing a unique identifier |
| Effective Production Status | epro | Effective development or production fusing status of an SoC |
| Effective Security Status | esec | Effective insecure or secure fusing status of an SoC |
| Certificate Production Status | cpro | Development or production fusing status of the signing certificate |
| Certificate Security Status | csec | Insecure or secure fusing status of the signing certificate |
| Certificate Epoch | cepo | Minimum certificate epoch of the device |
| Extended Security Domain | esdm | Additional security policy information (such as research fusing) |
| Restore Version | vnum | A version tuple to ensure a minimum OS version for accepting a manifest |
| Long OS Version | love | C-string formatted data representing the OS version |
| Allow Mix-N-Match | amnm | Allows using a heterogenous manifest chain for verifying objects (relaxes the constraint for enforcing chmh) |
| Data Only | data | Constraint to enforce rejection of the manifest by the environment that authorizes the use of trust caches |
| Boot Nonce Hash | bnch | Digest of the boot nonce used to enforce anti-replay by Secure ROM and iBoot |
| SEP Nonce | snon | Nonce used to enforce anti-replay for SEP objects |
| Cryptex1 Nonce Hash | cnch | Digest of the Cryptex1 nonce used to enforce anti-replay for Cryptex1 manifests |
| Nonce Domain | ndom | Domain of the nonce to use to enforce anti-replay |
| Research Mode | rsch | Constrains manifest to only research mode devices |
| Object Digest | dgst | Enforce an object’s digest matches the listing in the manifest |
| Boot Manifest Hash | chmh | Digest of the manifest used to boot the system, used to enforce use of a single manifest chain |
### Appendix: Trust Cache Format
The internal structure of a TrustCache.
[Overview](https://security.apple.com/documentation/private-cloud-compute/appendix_trustcache#overview)
Image4 manifests include the measurements of user-space code in their Trust Cache and Restore Trust Cache Objects, which contain the ~[CDHash](https://developer.apple.com/documentation/technotes/tn3126-inside-code-signing-hashes#Code-directory)~ values for each binary covered by the manifest.
A trust cache has a relatively simple structure, with a minimal header followed by an array of fixed-length entries:
TrustCacheEntryFlags ::= ENUMERATION {
    amfid(1),
    remLoBit(64),
    remHiBit(128),
}


TrustCacheEntry ::= SEQUENCE {
    cdHash               UInt8 [20],
    hashType             UInt8,
    TrustCacheEntryFlags UInt8,
    constraintCategory   UInt8,
    reserved             UInt8,
}


TrustCache ::= SEQUENCE {
    version    UInt8(2),
    uuid       UInt8 [16],
    entryCount UInt32,
    entries    TrustCacheEntry [...],
}
You can also dump this structure using the cryptexctl dump-trust-cache command and compare it to the CDHash of a binary you calculate using codesign(1).

### Appendix: Secure Boot Ticket Canonicalization
The construction of a release from an Image4 ticket.
[Overview](https://security.apple.com/documentation/private-cloud-compute/appendix_uniqtags#overview)
When CloudAttestation is producing canonical Image4 tickets, the 4CC uniq in personalized tickets determines which fields are redacted to produce canonical tickets.
At the time of publication, these fields are:
| **Field** | **Four Character Code** | **Provenance** | **Ticket** | **Purpose** |
|---|---|---|---|---|
| AP Nonce Hash | BNCH | Randomly generated by requestor and unique to each ticket | AP | Anti-replay |
| Certificate Epoch | CEPO | Injected by signing service | AP, Cryptex1 | Establishes authority of the certificate over the silicon |
| Unique Chip Identifier | ECID | Unique to SoC | AP | Binds manifest to specific SoC instance |
| Unique Device Identifier | UDID | Unique to SoC | Cryptex1 | Binds manifest to specific SoC instance |
| Cryptex1 Nonce Hash | cnch | Randomly generated by requestor and unique to each ticket | Cryptex1 | Anti-replay |
| SEP Nonce Hash | snon | Randomly generated by requestor and unique to each ticket | AP | Anti-replay |
| Software Update Freshness Nonce | snuf | Randomly generated by requestor and unique to each ticket | AP | Anti-replay |
| Server Nonce | srvn | Injected by signing service | AP, Cryptex1 | Salts the resulting ticket |
| Unique Tag List | uniq | Injected by signing service | AP, Cryptex1 | Lists all tags whose values should be replaced with null to produce a canonical representation |
### Appendix: Attestation Bundle Contents
The contents and validation of an attestation bundle.
[Overview](https://security.apple.com/documentation/private-cloud-compute/appendix_attestationbundle#overview)
Attestation bundles are Protobuf-encoded data structures with the following schema:
message AttestationBundle {
    bytes sep_attestation = 1; // DER-encoded SEP attestation
    bytes ap_ticket = 2; // DER-encoded AP Image4 manifest
    SealedHashLedger sealed_hashes = 3;
    repeated bytes provisioning_certificate_chain = 4;
    google.protobuf.Timestamp key_expiration = 6; // Unix timestamp of the key's expiration, as hinted by the attested device
    TransparencyProofs transparency_proofs = 8;
}


message SealedHashLedger {
    map<string, SealedHash> slots = 1;
}


message SealedHash {
    HashAlg hash_alg = 1;
    repeated Entry entries = 2;


    message Entry {
        int32 flags = 1; // Flags set for the sealed hash update
        bytes digest = 2; // The bytes ratcheted into the software sealed register


        oneof info {
            Cryptex cryptex = 3; // Cryptex entry
            Cryptex.Salt cryptex_salt = 4; // libCryptex defined value that serves as an end marker for a register
            SecureConfig secure_config = 5; // SecureConfig Entry
        }
    }
}


enum HashAlg {
    HASH_ALG_UNKNOWN = 0;
    HASH_ALG_SHA256 = 1;
    HASH_ALG_SHA384 = 2;
}


message Cryptex {
    bytes image4_manifest = 1; // DER-encoded cryptex Image4 manifest


    message Salt {
    }
}


message SecureConfig {
    bytes entry = 1; // JSON-encoded darwin-init config
    map<string, string> metadata = 2;
}


message TransparencyProofs {
    ATLogProofs proofs = 1;
}
The public part of the PCC node’s Request Encryption Key (REK) is released only under these conditions:
| **Node State** | **Constraint** | **Attestation Field Name** | **Notes** |
|---|---|---|---|
| SEAL_DATA_Avalue | Must match measurement of bundled AP ticket | within .sepAttestation |  |
| Finalized SSR value | Bundled cryptex tickets are measured, ratcheted, and must match | .sepAttestation[5C210D03-972B-433A-AEF7-E68A0249915B] | Register must be .locked |
| Finalized CSR value | SecureConfig database entries are measured, ratcheted, and must match | .sepAttestation[FB8BBEC2-BCC6-4ECC-964A-7BEB0C26674A] |  |
| REK flags | Flags must bind REK lifetime to OS instance and SSR+CSR state | within .sepAttestation | REK is bound to the entire set of current Sealed Hash Registers |
| AP fusing | AP must be production-fused | within .sepAttestation | Production AP cannot be paired with an Insecure SEP, so Secure SEP can be inferred |
| Restricted Execution Mode | Node must have entered REM | within .sepAttestation |  |
| Ephemeral Data Mode | Enabled | within .sepAttestation |  |
| Developer Mode | Disabled | within .sepAttestation |  |
| DCIK Certificate | Issued by the provisioning CA | .provisioningCertificateChain[0] |  |
| Node security policy | Customer security policy | .sepAttestation[FB8BBEC2-BCC6-4ECC-964A-7BEB0C26674A].entries[0] | Integrity covered by SEP Attestation’s SSR for this Sealed Hash |

# Appendix: Transparency Log
The protocol for communication with the transparency log service.
# [Overview](https://security.apple.com/documentation/private-cloud-compute/appendix_transparencylog#overview)
Private Cloud Compute’s transparency log is designed to enable security researchers to audit the integrity and contents of the log.
# [Log server protocol](https://security.apple.com/documentation/private-cloud-compute/appendix_transparencylog#Log-server-protocol)
The transparency log uses Protobuf encoding for most objects, but TLS 1.3 Presentation Language for objects that require deterministic encoding.
For all objects in the log:
Timestamps are specified in milliseconds elapsed since 00:00:00 UTC on January 1, 1970.
Hashes are calculated using SHA-256.
The value forProtocolVersion fields is 3.
The value for Application fields is PRIVATE_CLOUD_COMPUTE = 5.
PCC compute nodes use the following protocol to get proofs to include with attestations sent to client devices.
message ATLogProofRequest {
  ProtocolVersion version = 1;
  Application application = 2;


  bytes identifier = 3;
}


message ATLogProofResponse {
  Status status = 1;


  ATLogProofs proofs = 3;
}


message ATLogProofs {
  // Inclusion proof for this data if it exists in the log.
  LogEntry inclusionProof = 1;
  // If the inclusion proof isn't to a milestone root, this is included to prove consistency with a recent milestone.
  LogConsistency milestoneConsistency = 2;
}


message LogConsistency {
  SignedObject startSLH = 3; // Signed Log Head of a milestone root.
  SignedObject endSLH = 4; // Matches SLH in `inclusionProof`.
  repeated bytes proofHashes = 5;


  // Inclusion proof of the `endSLH` in the PAT, and the PAT head in the TLT.
  LogEntry patInclusionProof = 8;
  LogEntry tltInclusionProof = 9;
}


// The value and inclusion proof of a log leaf.
message LogEntry {
    LogType logType = 1;  // value is 5 for the PCC log
    SignedObject slh = 2;
    repeated bytes hashesOfPeersInPathToRoot = 3; // ordered with leaf at position 0, root-1 at end
    bytes nodeBytes = 4; // for the PCC log this is a ChangeLogNodeV2 wrapping a TLS encoded ATLeafData struct
    uint64 nodePosition = 5;
    NodeType nodeType = 6; // value is 7 for the PCC log
}


message LogHead {
    uint64 logBeginningMs = 1;
    uint64 logSize = 2;
    bytes logHeadHash = 3;
    uint64 revision = 4;
    LogType logType = 5;
    Application application = 6;
    uint64 treeId = 7;
    uint64 timestampMs = 8;
}


message SignedObject {
    // Parse as `LogHead` for PCC cases.
    bytes object        = 1;
    Signature signature = 2;
}


message Signature {
    bytes signature = 1;
    // This is a hash of the DER encoded public key used to verify the signature.
    bytes signingKeySPKIHash = 2;
    SignatureAlgorithm algorithm = 3;


    enum SignatureAlgorithm {
        UNKNOWN = 0;
        ECDSA_SHA256 = 1;
    }
}


enum Status {
    UNKNOWN_STATUS   = 0;
    OK               = 1;
    MUTATION_PENDING = 3;
    ALREADY_EXISTS   = 4;
    INTERNAL_ERROR   = 5;
    INVALID_REQUEST  = 6;
    NOT_FOUND        = 7;
}
The client makes this request daily for milestone roots. The request does not include Protobuf content. Instead, it specifies the known tree ID and last known milestone revision in HTTP headers.
message MilestoneRootsResponse {
  Status status = 1;


  // SLH at the client's last known revision, or revision 0 after a tree roll.
  SignedObject startSLH = 4;
  repeated MilestoneConsistency milestones = 5;


  // Inclusion proof of a recent milestone in the PAT, and the PAT head in the TLT.
  LogEntry patInclusionProof = 8;
  LogEntry tltInclusionProof = 9;
}


message MilestoneConsistency {
  // This is the end SLH of the consistency proof. The start SLH is the previous milestone
  // in the list of proofs, or startSLH for the first proof in the list.
  SignedObject milestoneSLH = 4;
  repeated bytes proofHashes = 5;
}
# [Log entry format](https://security.apple.com/documentation/private-cloud-compute/appendix_transparencylog#Log-entry-format)
PCC transparency log entries consist of a Protocol Buffer wrapper around a record encoded using TLS 1.3 Presentation Language.
message ChangeLogNodeV2 {
    bytes value = 1;
}


opaque HashValue<1..255>;


enum {


    (255)
} ExtensionType;


// In extensions vectors, there might only be one `Extension` of any `ExtensionType`; Extensions are ordered by `ExtensionType`.
struct {
    ExtensionType extensionType;
    opaque extensionData<0..65535>;
} Extension;


struct {
    SerializationVersion version;
    ATLeafType type;
    opaque description<0..255>;
    HashValue dataHash;
    uint64 expiryMs;


    Extension extensions<0..65535>;
} ATLeafData




enum {
    V1(1);


    (255)
} SerializationVersion;


enum {
    RELEASE(1);
    KEYBUNDLE_TGT(3);
    KEYBUNDLE_OTT(4);
    KEYBUNDLE_OHTTP(5);


    TEST_MARKER(100);


    (255)
} ATLeafType;
[Log integrity verification](https://security.apple.com/documentation/private-cloud-compute/appendix_transparencylog#Log-integrity-verification)
We constructed PCC’s transparency log by using Merkle trees, similar to ~[Certificate Transparency](https://datatracker.ietf.org/doc/html/rfc9162#section-2.1.1)~. PCC employs three types of trees:
Application Tree: Each leaf is the SHA-256 digest of a binary-encoded ~[release structure](https://security.apple.com/documentation/private-cloud-compute/releasetransparency#Release-data-structure)~.
Per-Application Tree: Each leaf contains the LogHead of each revision of the Application Tree.
Top-Level Tree: Leaves contain the Merkle tree root hash of every revision of the Per-Application Tree, as well as those for applications unrelated to PCC, meaning not every leaf is relevant to PCC.
### Note
The first leaf in each tree is special and contains a configuration bag for the tree.
In a valid transparency log, each of the following invariants holds:
Every revision of a tree represents an append-only extension of the previous revision’s leaves.
For each revision of the Application Tree, the root hash is a leaf in the Per-Application Tree.
For each revision of the Per-Application Tree, the root hash is a leaf in the Top-Level Tree.
You can verify the integrity of the transparency log by using the auditor APIs to download all known leaves of each level of tree, bottom to top starting from the Application Tree, and confirming the consistency of the tree as follows:
Within every leaf in the Top-Level Tree with the application identifierPRIVATE_CLOUD_COMPUTE (5) is a LogHead object that describes the tree shape and root hash of a particular revision of a Per-Application Tree. Reconstructing a Merkle Tree using all Per-Application Tree leaves from the range (0..<LogHead.logSize)must result in a SHA256 digest equal to LogHead.logHeadHash.
You can apply this same verification process to the Per-Application Tree, where each leaf is a LogHead representing a revision of the Application Tree.
The PCC Virtual Research Environment comes with a reference implementation that you can use to audit the correctness of the transparency log. For more information about using the VRE tooling for this purpose, see ~[Auditing the transparency log](https://security.apple.com/documentation/private-cloud-compute/inspectingreleases#Auditing-the-transparency-log)~.


### Appendix: Apple Intelligence Report
The transparency data available on client devices.
[Overview](https://security.apple.com/documentation/private-cloud-compute/appendix_appleintelligencereport#overview)
After you enable the Apple Intelligence Report in Settings > Privacy & Security, you can export the attestation bundles of the PCC nodes to which your device has encrypted requests.
The exported JSON file consists of two top-level keys:
modelRequests contains all Apple Intelligence requests, both requests that are handled locally (executionEnvironment: OnDevice), and requests that are processed by Private Cloud Compute (executionEnvironment: PrivateCloudCompute).
privateCloudComputeRequests contains metadata for requests processed by Private Cloud Compute:
pipelineKind is always tie-cloudboard-apple-com, indicating it was routed to a PCC node running a TIE.
pipelineParameters are additional request parameters that are visible to the PCC Gateway for routing decisions, like model or adapter.
attestations is an array of attestation bundles of PCC nodes to which the device released the Data Encryption Key. The structure of attestation bundles is described in ~[Appendix: Attestation Bundle Contents](https://security.apple.com/documentation/private-cloud-compute/appendix_attestationbundle)~.





Apple Intelligence On-device vs Cloud features

Apple Intelligence was released recently - I wanted to put to the test Apple's words on privacy and on-device AI processing. Through experimentation (disabling internet and the Apple Intelligence privacy report in settings) I was able to narrow down which services are done on-device and which are done on Apple's Private Cloud Compute servers.

[More about PCC](https://security.apple.com/blog/private-cloud-compute/)

NOTE: I am not here to say that everything should be done on-device, nor am I saying PCC is unsafe. I am simply providing disclosure regarding each feature. Happy to answer more questions in the comments!

***Updated as of MacOS 15.2 stable - 12/15/2024***

**Writing Tools:**

* **On-device:** Proofread, rewrite, friendly, professional, concise
* **PCC:** Summary, key points, list, table, describe your change
* **ChatGPT:** Compose

**Mail:**

* **On-device:** Email preview summaries, Priority emails
* **PCC:** Email summarization, smart reply

**Messages:**

* **On-device:** Message preview summaries, Smart reply

**Siri:**

* **On-device:** (I was able to ask about emails and calendar events)
* **ChatGPT:** Any ChatGPT requests (will inform you before sending to ChatGPT)

**Safari:**

* **PCC:** Web page summaries

**Notes:**

* **PCC:** Audio recording summaries

**Photos:**

* **On-device:**
  * Intelligent search (after indexing)
  * Clean up (after downloading the clean-up model)

**Notifications/Focus:**

* **On-device:** Notification summaries, Reduce interruptions focus

**Image Playground:**

* **On-device:** Image generation (after image model is downloaded)
