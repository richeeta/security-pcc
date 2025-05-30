// Copyright © 2024 Apple Inc. All Rights Reserved.

// APPLE INC.
// PRIVATE CLOUD COMPUTE SOURCE CODE INTERNAL USE LICENSE AGREEMENT
// PLEASE READ THE FOLLOWING PRIVATE CLOUD COMPUTE SOURCE CODE INTERNAL USE LICENSE AGREEMENT (“AGREEMENT”) CAREFULLY BEFORE DOWNLOADING OR USING THE APPLE SOFTWARE ACCOMPANYING THIS AGREEMENT(AS DEFINED BELOW). BY DOWNLOADING OR USING THE APPLE SOFTWARE, YOU ARE AGREEING TO BE BOUND BY THE TERMS OF THIS AGREEMENT. IF YOU DO NOT AGREE TO THE TERMS OF THIS AGREEMENT, DO NOT DOWNLOAD OR USE THE APPLE SOFTWARE. THESE TERMS AND CONDITIONS CONSTITUTE A LEGAL AGREEMENT BETWEEN YOU AND APPLE.
// IMPORTANT NOTE: BY DOWNLOADING OR USING THE APPLE SOFTWARE, YOU ARE AGREEING ON YOUR OWN BEHALF AND/OR ON BEHALF OF YOUR COMPANY OR ORGANIZATION TO THE TERMS OF THIS AGREEMENT.
// 1. As used in this Agreement, the term “Apple Software” collectively means and includes all of the Apple Private Cloud Compute materials provided by Apple here, including but not limited to the Apple Private Cloud Compute software, tools, data, files, frameworks, libraries, documentation, logs and other Apple-created materials. In consideration for your agreement to abide by the following terms, conditioned upon your compliance with these terms and subject to these terms, Apple grants you, for a period of ninety (90) days from the date you download the Apple Software, a limited, non-exclusive, non-sublicensable license under Apple’s copyrights in the Apple Software to download, install, compile and run the Apple Software internally within your organization only on a single Apple-branded computer you own or control, for the sole purpose of verifying the security and privacy characteristics of Apple Private Cloud Compute. This Agreement does not allow the Apple Software to exist on more than one Apple-branded computer at a time, and you may not distribute or make the Apple Software available over a network where it could be used by multiple devices at the same time. You may not, directly or indirectly, redistribute the Apple Software or any portions thereof. The Apple Software is only licensed and intended for use as expressly stated above and may not be used for other purposes or in other contexts without Apple's prior written permission. Except as expressly stated in this notice, no other rights or licenses, express or implied, are granted by Apple herein.
// 2. The Apple Software is provided by Apple on an "AS IS" basis. APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS, SYSTEMS, OR SERVICES. APPLE DOES NOT WARRANT THAT THE APPLE SOFTWARE WILL MEET YOUR REQUIREMENTS, THAT THE OPERATION OF THE APPLE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, THAT DEFECTS IN THE APPLE SOFTWARE WILL BE CORRECTED, OR THAT THE APPLE SOFTWARE WILL BE COMPATIBLE WITH FUTURE APPLE PRODUCTS, SOFTWARE OR SERVICES. NO ORAL OR WRITTEN INFORMATION OR ADVICE GIVEN BY APPLE OR AN APPLE AUTHORIZED REPRESENTATIVE WILL CREATE A WARRANTY.
// 3. IN NO EVENT SHALL APPLE BE LIABLE FOR ANY DIRECT, SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, COMPILATION OR OPERATION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 4. This Agreement is effective until terminated. Your rights under this Agreement will terminate automatically without notice from Apple if you fail to comply with any term(s) of this Agreement. Upon termination, you agree to cease all use of the Apple Software and destroy all copies, full or partial, of the Apple Software. This Agreement constitutes the entire understanding of the parties with respect to the subject matter contained herein, and supersedes all prior negotiations, representations, or understandings, written or oral. This Agreement will be governed and construed in accordance with the laws of the State of California, without regard to its choice of law rules.
// You may report security issues about Apple products to product-security@apple.com, as described here: https://www.apple.com/support/security/. Non-security bugs and enhancement requests can be made via https://bugreport.apple.com as described here: https://developer.apple.com/bug-reporting/
// EA1937
// 10/02/2024

//
//  TC2TrustedRequestMetadata.swift
//  PrivateCloudCompute
//
//  Copyright © 2024 Apple Inc. All rights reserved.
//

import Foundation

package struct TC2TrustedRequestEndpointMetadata: Sendable, Codable, TC2JSON {
    package let nodeState: String
    package let nodeIdentifier: String
    package let ohttpContext: UInt64
    package let hasReceivedSummary: Bool
    package let dataReceived: UInt64
    package let cloudOSVersion: String?
    package let cloudOSReleaseType: String?
    package let maybeValidatedCellID: String?
    package let ensembleID: String?
    package let isFromCache: Bool

    package init(nodeState: String, nodeIdentifier: String, ohttpContext: UInt64, hasReceivedSummary: Bool, dataReceived: UInt64, cloudOSVersion: String?, cloudOSReleaseType: String?, maybeValidatedCellID: String?, ensembleID: String?, isFromCache: Bool)
    {
        self.nodeState = nodeState
        self.nodeIdentifier = nodeIdentifier
        self.ohttpContext = ohttpContext
        self.hasReceivedSummary = hasReceivedSummary
        self.dataReceived = dataReceived
        self.cloudOSVersion = cloudOSVersion
        self.cloudOSReleaseType = cloudOSReleaseType
        self.maybeValidatedCellID = maybeValidatedCellID
        self.ensembleID = ensembleID
        self.isFromCache = isFromCache
    }
}

package struct TC2TrustedRequestMetadata: Sendable, Codable, TC2JSON {
    package let clientRequestID: UUID
    package let serverRequestID: UUID
    package let environment: String
    package let creationDate: Date
    package let bundleIdentifier: String
    package let featureIdentifier: String?
    package let sessionIdentifier: UUID?
    package let qos: String
    package let workloadName: String
    package let workloadParameters: [String: String]
    package let state: String
    package let payloadTransportState: String
    package let responseState: String
    package let responseCode: Int?
    package let ropesVersion: String?
    package let endpoints: [TC2TrustedRequestEndpointMetadata]

    package init(
        clientRequestID: UUID, serverRequestID: UUID, environment: String, creationDate: Date, bundleIdentifier: String, featureIdentifier: String?, sessionIdentifier: UUID?, qos: String, parameters: TC2RequestParameters, state: String,
        payloadTransportState: String,
        responseState: String, responseCode: Int?, ropesVersion: String?, endpoints: [TC2TrustedRequestEndpointMetadata]
    ) {
        self.clientRequestID = clientRequestID
        self.serverRequestID = serverRequestID
        self.environment = environment
        self.creationDate = creationDate
        self.bundleIdentifier = bundleIdentifier
        self.featureIdentifier = featureIdentifier
        self.sessionIdentifier = sessionIdentifier
        self.qos = qos
        self.workloadName = parameters.pipelineKind
        self.workloadParameters = parameters.pipelineArguments
        self.state = state
        self.payloadTransportState = payloadTransportState
        self.responseState = responseState
        self.responseCode = responseCode
        self.ropesVersion = ropesVersion
        self.endpoints = endpoints
    }
}

package struct TC2TrustedRequestFactoryMetadata: Sendable, Codable, TC2JSON {
    package let requests: [TC2TrustedRequestMetadata]

    package init(requests: [TC2TrustedRequestMetadata]) {
        self.requests = requests
    }
}

package struct TC2TrustedRequestFactoriesMetadata: Sendable, Codable, TC2JSON {
    package let requests: [TC2TrustedRequestFactoryMetadata]

    package init(requests: [TC2TrustedRequestFactoryMetadata]) {
        self.requests = requests
    }
}

// These types exist solely to write log entries that record the various requests.
// Once we have moved away from the existing `thtool request` implementation, we
// will delete `TC2TrustedRequestMetadata` et al and only the following will remain.
// The reason for the separation right now is that some of the names and formats are
// wrong and the json should be pretty stable.

package enum RequestLogEntryType: String, Codable {
    case trustedRequest
    case prefetchRequest  // Unused
}

package struct TrustedRequestLogEntry: Sendable, Codable {
    static let dateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    package let type: RequestLogEntryType
    package let clientRequestID: UUID
    package let serverRequestID: UUID
    package let environment: String
    package let creationDate: String
    package let bundleIdentifier: String
    package let featureIdentifier: String?
    package let sessionIdentifier: UUID?
    package let qos: String
    package let workloadName: String
    package let workloadParameters: [String: String]
    package let state: String
    package let payloadTransportState: String
    package let responseState: String
    package let responseCode: Int?
    package let ropesVersion: String?
    package let endpoints: [TC2TrustedRequestEndpointMetadata]

    package init(_ metadata: TC2TrustedRequestMetadata) {
        self.type = .trustedRequest
        self.clientRequestID = metadata.clientRequestID
        self.serverRequestID = metadata.serverRequestID
        self.environment = metadata.environment
        self.creationDate = metadata.creationDate.formatted(Self.dateStyle)
        self.bundleIdentifier = metadata.bundleIdentifier
        self.featureIdentifier = metadata.featureIdentifier
        self.sessionIdentifier = metadata.sessionIdentifier
        self.qos = metadata.qos
        self.workloadName = metadata.workloadName
        self.workloadParameters = metadata.workloadParameters
        self.state = metadata.state
        self.payloadTransportState = metadata.payloadTransportState
        self.responseState = metadata.responseState
        self.responseCode = metadata.responseCode
        self.ropesVersion = metadata.ropesVersion
        self.endpoints = metadata.endpoints
    }
}
