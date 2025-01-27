//
// Copyright (C) 2005-2021 Alfresco Software Limited.
//
// This file is part of the Alfresco Content Mobile iOS App.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import AlfrescoContent
import AlfrescoCore
import Alamofire

class NodeOperations {
    var accountService: AccountService?
    var renditionTimer: Timer?

    // MARK: - Init

    required init(accountService: AccountService?) {
        self.accountService = accountService
    }

    // MARK: - Public interface

    func sessionForCurrentAccount(completionHandler: @escaping ((AuthenticationProviderProtocol) -> Void)) {
        accountService?.getSessionForCurrentAccount(completionHandler: { authenticationProvider in
            AlfrescoContentAPI.customHeaders = authenticationProvider.authorizationHeader()

            completionHandler(authenticationProvider)
        })
    }

    func fetchNodeChildren(for guid: String,
                           pagination: RequestPagination,
                           relativePath: String? = nil,
                           completion: @escaping ((_ data: NodeChildAssociationPaging?,
                                                   _ error: Error?) -> Void)) {
        sessionForCurrentAccount { _ in
            NodesAPI.listNodeChildren(nodeId: guid,
                                      skipCount: pagination.skipCount,
                                      maxItems: pagination.maxItems,
                                      include: [APIConstants.Include.isFavorite,
                                                APIConstants.Include.path,
                                                APIConstants.Include.allowableOperations,
                                                APIConstants.Include.properties],
                                      relativePath: relativePath) { (result, error) in
                completion(result, error)
            }
        }
    }

    func fetchNodeDetails(for guid: String,
                          relativePath: String? = nil,
                          completion: @escaping ((_ data: NodeEntry?,
                                                         _ error: Error?) -> Void)) {
        sessionForCurrentAccount { _ in
            NodesAPI.getNode(nodeId: guid,
                             include: [APIConstants.Include.path,
                                       APIConstants.Include.isFavorite,
                                       APIConstants.Include.allowableOperations,
                                       APIConstants.Include.properties],
                             relativePath: relativePath) { (result, error) in
                completion(result, error)

            }
        }
    }

    func createNode(nodeId: String,
                    name: String,
                    description: String?,
                    nodeExtension: String,
                    fileData: Data,
                    autoRename: Bool,
                    completionHandler: @escaping (ListNode?, Error?) -> Void) {
        let nodeBody = NodeBodyCreate(name: name + "." + nodeExtension,
                                      nodeType: "cm:content",
                                      aspectNames: nil,
                                      properties: nodeProperties(for: name,
                                                                 description: description),
                                      permissions: nil,
                                      definition: nil,
                                      relativePath: nil,
                                      association: nil,
                                      secondaryChildren: nil,
                                      targets: nil)
        NodesAPI.createNode(nodeId: nodeId,
                            nodeBody: nodeBody,
                            fileData: fileData,
                            autoRename: autoRename,
                            description: description) { (nodeEntry, error) in
            if let node = nodeEntry?.entry {
                let listNode = NodeChildMapper.create(from: node)
                completionHandler(listNode, nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    func createNode(nodeId: String,
                    name: String,
                    description: String?,
                    autoRename: Bool,
                    completionHandler: @escaping (ListNode?, Error?) -> Void) {
        let nodeBody = NodeBodyCreate(name: name,
                                      nodeType: "cm:folder",
                                      aspectNames: nil,
                                      properties: nodeProperties(for: name,
                                                                 description: description),
                                      permissions: nil,
                                      definition: nil,
                                      relativePath: nil,
                                      association: nil,
                                      secondaryChildren: nil,
                                      targets: nil)
        let requestBuilder = NodesAPI.createNodeWithRequestBuilder(nodeId: nodeId,
                                                                   nodeBodyCreate: nodeBody,
                                                                   autoRename: autoRename,
                                                                   include: nil,
                                                                   fields: nil)
        requestBuilder.execute { (result, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let node = result?.body?.entry {
                let listNode = NodeChildMapper.create(from: node)
                completionHandler(listNode, nil)
            }
        }
    }

    func fetchContentURL(for node: ListNode?) -> URL? {
        guard let ticket = accountService?.activeAccount?.getTicket(),
              let basePathURL = accountService?.activeAccount?.apiBasePath,
              let listNode = node,
              let previewURL = URL(string: basePathURL + "/" +
                                    String(format: APIConstants.Path.getNodeContent, listNode.guid, ticket))
        else { return nil }
        return previewURL
    }

    private func nodeProperties(for name: String, description: String?) -> JSONValue {
        if let description = description {
            return JSONValue(dictionaryLiteral:
                                ("cm:title", JSONValue(stringLiteral: name)),
                             ("cm:description", JSONValue(stringLiteral: description)))
        } else {
            return JSONValue(dictionaryLiteral:
                                ("cm:title", JSONValue(stringLiteral: name)))
        }
    }
}
