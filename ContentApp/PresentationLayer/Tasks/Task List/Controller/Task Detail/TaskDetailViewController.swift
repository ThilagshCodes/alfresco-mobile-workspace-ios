//
// Copyright (C) 2005-2022 Alfresco Software Limited.
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

import UIKit
import AlfrescoContent
import MaterialComponents

class TaskDetailViewController: SystemSearchViewController {

    @IBOutlet weak var progressView: MDCProgressView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var completeTaskView: UIView!
    @IBOutlet weak var completeTaskButton: MDCButton!
    var viewModel: TaskDetailViewModel { return controller.viewModel }
    lazy var controller: TaskDetailController = { return TaskDetailController( currentTheme: coordinatorServices?.themingService?.activeTheme) }()
    let buttonWidth = 65.0
    let buttonHeight = 45.0
    var editButton = UIButton(type: .custom)
    private var dialogTransitionController: MDCDialogTransitionController?
    let refreshGroup = DispatchGroup()
    private var cameraCoordinator: CameraScreenCoordinator?
    private var photoLibraryCoordinator: PhotoLibraryScreenCoordinator?
    private var fileManagerCoordinator: FileManagerScreenCoordinator?

    // MARK: - View did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.services = coordinatorServices ?? CoordinatorServices()
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.navigationItem.setHidesBackButton(true, animated: true)
        controller.registerEvents()
        addBackButton()
        progressView.progress = 0
        progressView.mode = .indeterminate
        applyTheme()
        applyLocalization()
        registerCells()
        addAccessibility()
        controller.buildViewModel()
        setupBindings()
        getTaskDetails()
        getTaskComments()
        getTaskAttachments()
        AnalyticsManager.shared.pageViewEvent(for: Event.Page.taskDetailScreen)
        checkForCompleteTaskButton()
        addEditButton()
        storeReadOnlyTaskDetails()
        self.dialogTransitionController = MDCDialogTransitionController()
        updateCompleteTaskUI()

        // ReSignIn Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleReSignIn(notification:)),
                                               name: Notification.Name(KeyConstants.Notification.reSignin),
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        updateTheme()
        controller.updateLatestComment()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.isHidden = false
    }
    
    func updateTheme() {
        let activeTheme = coordinatorServices?.themingService?.activeTheme
        progressView.progressTintColor = activeTheme?.primaryT1Color
        progressView.trackTintColor = activeTheme?.primary30T1Color
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    private func applyLocalization() {
        self.title = LocalizationConstants.Tasks.taskDetailTitle
    }
    
    func registerCells() {
        self.tableView.register(UINib(nibName: CellConstants.TableCells.titleCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.titleCell)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.infoCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.infoCell)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.priorityCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.priorityCell)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.addCommentCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.addCommentCell)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.commentCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.commentCell)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.taskHeaderCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.taskHeaderCell)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.emptyPlaceholderCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.emptyPlaceholderCell)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.taskAttachment, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.taskAttachment)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.addTaskAttachment, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.addTaskAttachment)
        self.tableView.register(UINib(nibName: CellConstants.TableCells.spaceCell, bundle: nil), forCellReuseIdentifier: CellConstants.TableCells.spaceCell)
    }
    
    private func addAccessibility() {
        progressView.isAccessibilityElement = false
    }
    
    // MARK: - Public Helpers

    func applyTheme() {
        guard let currentTheme = coordinatorServices?.themingService?.activeTheme,
              let buttonScheme = coordinatorServices?.themingService?.containerScheming(for: .dialogButton)
        else { return }
        
        completeTaskView.backgroundColor = currentTheme.surfaceColor
        completeTaskButton.applyContainedTheme(withScheme: buttonScheme)
        completeTaskButton.isUppercaseTitle = false
        completeTaskButton.setTitle(LocalizationConstants.Tasks.completeTitle, for: .normal)
        completeTaskButton.layer.cornerRadius = UIConstants.cornerRadiusDialog
        completeTaskButton.setShadowColor(.clear, for: .normal)
        completeTaskButton.setTitleColor(.white, for: .normal)
        
        editButton.setTitleColor(currentTheme.primaryT1Color, for: .normal)
        editButton.titleLabel?.font = currentTheme.buttonTextStyle.font
    }
    
    func startLoading() {
        progressView?.startAnimating()
        progressView?.setHidden(false, animated: true)
    }

    func stopLoading() {
        progressView?.stopAnimating()
        progressView?.setHidden(true, animated: false)
    }

    @objc private func handleReSignIn(notification: Notification) {
        getTaskDetails()
    }
    
    private func checkForCompleteTaskButton() {
        DispatchQueue.main.async {
            if self.viewModel.isAllowedToCompleteTask() {
                self.completeTaskView.isHidden = false
                self.tableView.contentInset.bottom = 90
            } else {
                self.completeTaskView.isHidden = true
                self.tableView.contentInset.bottom = 50
            }
        }
    }
    
    private func addBackButton() {
        let backButton = UIButton(type: .custom)
        backButton.accessibilityIdentifier = "backButton"
        backButton.accessibilityLabel = LocalizationConstants.Accessibility.back
        backButton.frame = CGRect(x: 0.0, y: 0.0,
                                  width: 30.0,
                                    height: 30.0)
        backButton.imageView?.contentMode = .scaleAspectFill
        backButton.layer.masksToBounds = true
        backButton.addTarget(self,
                               action: #selector(backButtonAction),
                               for: UIControl.Event.touchUpInside)
        backButton.setImage(UIImage(named: "ic-back"),
                              for: .normal)

        let searchBarButtonItem = UIBarButtonItem(customView: backButton)
        searchBarButtonItem.accessibilityIdentifier = "backBarButton"
        let currWidth = searchBarButtonItem.customView?.widthAnchor.constraint(equalToConstant: 30.0)
        currWidth?.isActive = true
        let currHeight = searchBarButtonItem.customView?.heightAnchor.constraint(equalToConstant: 30.0)
        currHeight?.isActive = true
        self.navigationItem.leftBarButtonItem = searchBarButtonItem
    }
    
    // MARK: - Back Button Action
    @objc func backButtonAction() {
        if viewModel.isEditTask && (viewModel.isTaskUpdated() || viewModel.isAssigneeChanged()) {
            showAlertToSaveProgress()
        } else {
            self.backAndRefreshAction(isRefreshList: false)
        }
    }
    
    // MARK: - Set up Bindings
    private func setupBindings() {
        
        /* observer loader */
        viewModel.isLoading.addObserver { [weak self] (isLoading) in
            guard let sSelf = self else { return }
            if isLoading {
                sSelf.startLoading()
            } else {
                sSelf.stopLoading()
            }
        }
        
        /* observing rows */
        viewModel.rowViewModels.addObserver() { [weak self] (rows) in
            guard let sSelf = self else { return }
            DispatchQueue.main.async {
                sSelf.tableView.reloadData()
            }
        }
        
        /* observing comments */
        viewModel.comments.addObserver() { [weak self] (comments) in
            guard let sSelf = self else { return }
            DispatchQueue.main.async {
                sSelf.tableView.reloadData()
            }
        }
        
        /* observe add comment action */
        viewModel.viewAllCommentsAction = { [weak self] (isAddComment) in
            guard let sSelf = self else { return }
            sSelf.showComments(isAddComment: isAddComment)
        }
        
        /* observing attachments */
        viewModel.attachments.addObserver { [weak self] (attachments) in
            guard let sSelf = self else { return }
            DispatchQueue.main.async {
                sSelf.tableView.reloadData()
            }
        }
        
        /* observe view all attachments action */
        viewModel.viewAllAttachmentsAction = { [weak self] in
            guard let sSelf = self else { return }
            sSelf.viewAllAttachments()
        }
        
        /* observer did select task attachment */
        viewModel.didSelectTaskAttachment = { [weak self] (attachment) in
            guard let sSelf = self else { return }
            sSelf.didSelectAttachment(attachment: attachment)
        }
        
        /* observer did select delete attachment */
        viewModel.didSelectDeleteAttachment = { [weak self] (attachment) in
            guard let sSelf = self else { return }
            sSelf.didSelectDeleteAttachment(attachment: attachment)
        }
        
        /* observing read more description */
        controller.didSelectReadMoreActionForDescription = {
            self.showTaskDescription()
        }
        
        /* observing edit title */
        controller.didSelectEditTitle = {
            self.editTitleAndDescriptionAction()
        }
        
        /* observing edit due date */
        controller.didSelectEditDueDate = {
            self.editDueDateAction()
        }
        
        /* observing reset due date */
        controller.didSelectResetDueDate = {
            self.resetDueDateAction()
        }
        
        /* observing priority */
        controller.didSelectPriority = {
            self.changePriorityAction()
        }
        
        /* observing assignee */
        controller.didSelectAssignee = {
            self.changeAssigneeAction()
        }
        
        /* observer did select add attachment */
        controller.didSelectAddAttachment = {
            self.addAttachmentButtonAction()
        }
    }

    private func getTaskDetails() {
        let taskID = viewModel.taskID
        viewModel.taskDetails(with: taskID) { [weak self] taskNodes, error in
            guard let sSelf = self else { return }
            if error == nil {
                sSelf.controller.buildViewModel()
                sSelf.checkForCompleteTaskButton()
            }
        }
    }
    
    private func getTaskComments() {
        let taskID = viewModel.taskID
        viewModel.taskComments(with: taskID) { [weak self] comments, error in
            guard let sSelf = self else { return }
            if error == nil {
                sSelf.viewModel.comments.value = comments
                sSelf.controller.buildViewModel()
            }
        }
    }
    
    private func getTaskAttachments() {
        let taskID = viewModel.taskID
        viewModel.taskAttachments(with: taskID) { [weak self] taskAttachments, error in
            guard let sSelf = self else { return }
            if error == nil {
                sSelf.viewModel.attachments.value = taskAttachments

                // Insert nodes to be uploaded
                _ = sSelf.viewModel.uploadTransferDataAccessor.queryAll(for: sSelf.viewModel.taskID, isTaskAttachment: true) { uploadTransfers in
                    sSelf.controller.insert(uploadTransfers: uploadTransfers)
                }
                
                sSelf.viewModel.isAttachmentsLoaded = true
                sSelf.controller.buildViewModel()
            }
        }
    }
    
    private func showComments(isAddComment: Bool) {
        let storyboard = UIStoryboard(name: StoryboardConstants.storyboard.tasks, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: StoryboardConstants.controller.taskComments) as? TaskCommentsViewController {
            viewController.coordinatorServices = coordinatorServices
            viewController.viewModel.isShowKeyboard = isAddComment
            viewController.viewModel.comments = viewModel.comments
            viewController.viewModel.task = viewModel.task
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func viewAllAttachments() {
        let storyboard = UIStoryboard(name: StoryboardConstants.storyboard.tasks, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: StoryboardConstants.controller.taskAttachments) as? TaskAttachmentsViewController {
            viewController.coordinatorServices = coordinatorServices
            viewController.viewModel.attachments = viewModel.attachments
            viewController.viewModel.task = viewModel.task
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func didSelectAttachment(attachment: ListNode) {
        if attachment.syncStatus == .undefined || attachment.syncStatus == .synced {
            let title = attachment.title
            let attachmentId = attachment.guid
            viewModel.downloadContent(for: title, contentId: attachmentId) {[weak self] path, error in
                guard let sSelf = self, let path = path else { return }
                sSelf.viewModel.showPreviewController(with: path, attachment: attachment, navigationController: sSelf.navigationController)
            }
        } else {
            viewModel.startFileCoordinator(for: attachment, presenter: self.navigationController)
        }
    }
    
    @IBAction func completeTaskButtonAction(_ sender: Any) {
        if viewModel.isEditTask { return }
        
        let title = LocalizationConstants.Dialog.completeTaskTitle
        var message = LocalizationConstants.Dialog.completeTaskMessage
        if viewModel.isAttachmentsPendingForUpload() {
            message = LocalizationConstants.Dialog.completeTaskWhileAttachmentsInProgress
        }
        
        let confirmAction = MDCAlertAction(title: LocalizationConstants.Dialog.confirmTitle) { [weak self] _ in
            guard let sSelf = self else { return }
            AnalyticsManager.shared.didTapTaskCompleteAlert()
            sSelf.completeTask()
        }
        confirmAction.accessibilityIdentifier = "confirmActionButton"
        
        let cancelAction = MDCAlertAction(title: LocalizationConstants.General.cancel) { _ in }
        cancelAction.accessibilityIdentifier = "cancelActionButton"

        _ = self.showDialog(title: title,
                                       message: message,
                                       actions: [confirmAction, cancelAction],
                                       completionHandler: {})
    }
    
    @objc private func completeTask() {
        let taskID = viewModel.taskID
        viewModel.completeTask(with: taskID) {[weak self] isSuccess in
            guard let sSelf = self else { return }
            if isSuccess {
                sSelf.backAndRefreshAction(isRefreshList: true)
            }
        }
    }
    
    private func backAndRefreshAction(isRefreshList: Bool) {
        if isRefreshList {
            self.viewModel.didRefreshTaskList?()
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    private func showTaskDescription() {
        let storyboard = UIStoryboard(name: StoryboardConstants.storyboard.tasks, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: StoryboardConstants.controller.taskDescription) as? TaskDescriptionDetailViewController {
            viewController.coordinatorServices = coordinatorServices
            viewController.viewModel.task = viewModel.task
            
            let navigationController = UINavigationController(rootViewController: viewController)
            self.present(navigationController, animated: true)
        }
    }
}

// MARK: - Table View Data Source and Delegates
extension TaskDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowViewModels.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowViewModel = viewModel.rowViewModels.value[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: controller.cellIdentifier(for: rowViewModel), for: indexPath)
        if let cell = cell as? CellConfigurable {
            cell.setup(viewModel: rowViewModel)
        }
        
        if let theme = coordinatorServices?.themingService {
            if cell is TitleTableViewCell {
                (cell as? TitleTableViewCell)?.applyTheme(with: theme)
            } else if cell is InfoTableViewCell {
                (cell as? InfoTableViewCell)?.applyTheme(with: theme)
            } else if cell is PriorityTableViewCell {
                (cell as? PriorityTableViewCell)?.applyTheme(with: theme)
            } else if cell is AddCommentTableViewCell {
                (cell as? AddCommentTableViewCell)?.applyTheme(with: theme)
            } else if cell is TaskCommentTableViewCell {
                (cell as? TaskCommentTableViewCell)?.applyTheme(with: theme)
            } else if cell is TaskHeaderTableViewCell {
                (cell as? TaskHeaderTableViewCell)?.applyTheme(with: theme)
            } else if cell is EmptyPlaceholderTableViewCell {
                (cell as? EmptyPlaceholderTableViewCell)?.applyTheme(with: theme)
            } else if cell is TaskAttachmentTableViewCell {
                (cell as? TaskAttachmentTableViewCell)?.applyTheme(with: theme)
            } else if cell is AddAttachmentTableViewCell {
                (cell as? AddAttachmentTableViewCell)?.applyTheme(with: theme)
            } else if cell is SpaceTableViewCell {
                (cell as? SpaceTableViewCell)?.applyTheme(with: theme)
            }
        }
        
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowViewModel = viewModel.rowViewModels.value[indexPath.row]
        switch rowViewModel {
        case is SpaceTableCellViewModel:
            return 40.0
        default:
            return UITableView.automaticDimension
        }
    }
}

// MARK: - Edit flow
extension TaskDetailViewController {
    
    private func updateCompleteTaskUI() {
        guard let currentTheme = coordinatorServices?.themingService?.activeTheme else { return }

        if viewModel.isEditTask {
            completeTaskButton.isUserInteractionEnabled = false
            completeTaskButton.setBackgroundColor(currentTheme.dividerColor)
            completeTaskButton.setTitleColor(currentTheme.onSurface12TextColor, for: .normal)
        } else {
            completeTaskButton.isUserInteractionEnabled = true
            completeTaskButton.setBackgroundColor(currentTheme.primaryT1Color)
            completeTaskButton.setTitleColor(.white, for: .normal)
        }
    }
    
    private func addEditButton() {
        if viewModel.isTaskCompleted { return }
        editButton.accessibilityIdentifier = "edit-done-button"
        editButton.frame = CGRect(x: 0.0, y: 0.0, width: buttonWidth, height: buttonHeight)
        editButton.addTarget(self,
                               action: #selector(editButtonTapped),
                               for: UIControl.Event.touchUpInside)
        editButton.setTitle(viewModel.editButtonTitle, for: .normal)
        editButton.titleLabel?.numberOfLines = 1
        editButton.titleLabel?.adjustsFontSizeToFitWidth = true
        editButton.titleLabel?.lineBreakMode = .byClipping

        let searchBarButtonItem = UIBarButtonItem(customView: editButton)
        searchBarButtonItem.accessibilityIdentifier = "barButton"
        let currHeight = searchBarButtonItem.customView?.heightAnchor.constraint(equalToConstant: buttonHeight)
        currHeight?.isActive = true
        self.navigationItem.rightBarButtonItem = searchBarButtonItem
    }
    
    @objc func editButtonTapped() {
        guard viewModel.services?.connectivityService?.hasInternetConnection() == true else { return }
        if !viewModel.isEditTask {
            viewModel.isEditTask = true
            AnalyticsManager.shared.didTapEditTask()
            editButton.setTitle(viewModel.editButtonTitle, for: .normal)
            updateCompleteTaskUI()
            controller.buildViewModel()
            storeReadOnlyTaskDetails()

        } else {
            AnalyticsManager.shared.didTapDoneTask()
            saveEdittedTask()
        }
    }
    
    private func updateUIAfterTaskEdit() {
        DispatchQueue.main.async {
            self.viewModel.isEditTask = false
            self.editButton.setTitle(self.viewModel.editButtonTitle, for: .normal)
            self.updateCompleteTaskUI()
            self.controller.buildViewModel()
        }
    }
    
    private func storeReadOnlyTaskDetails() {
        if viewModel.isEditTask {
            viewModel.readOnlyTask = viewModel.task
        }
    }
}

// MARK: - Edit Task Name and description
extension TaskDetailViewController {
    
    private func editTitleAndDescriptionAction() {
        
        let viewController = CreateNodeSheetViewControler.instantiateViewController()
        let createTaskViewModel = CreateTaskViewModel(coordinatorServices: coordinatorServices,
                                                      createTaskViewType: .editTask,
                                                      task: viewModel.task)
        
        viewController.coordinatorServices = coordinatorServices
        viewController.createTaskViewModel = createTaskViewModel
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = dialogTransitionController
        viewController.mdc_dialogPresentationController?.dismissOnBackgroundTap = false
        self.present(viewController, animated: true)
        viewController.callBack = { [weak self] (task, title, description) in
            guard let sSelf = self else { return }
            sSelf.updateTaskTitleAndDescription(with: title, description: description)
        }
    }

    private func updateTaskTitleAndDescription(with title: String?, description: String?) {
        viewModel.task?.name = title
        viewModel.task?.description = description
        controller.buildViewModel()
    }
}

// MARK: - Edit Due Date
extension TaskDetailViewController {
    
    func editDueDateAction() {
        
        let viewController = DatePickerViewController.instantiateViewController()
        let bottomSheet = MDCBottomSheetController(contentViewController: viewController)
        bottomSheet.dismissOnDraggingDownSheet = false
        viewController.coordinatorServices = coordinatorServices
        viewController.viewModel.selectedDate = viewModel.dueDate
        self.navigationController?.present(bottomSheet, animated: true, completion: nil)
        viewController.callBack = { [weak self] (dueDate) in
            guard let sSelf = self else { return }
            sSelf.updateTaskDueDate(with: dueDate)
        }
    }
    
    func resetDueDateAction() {
        self.updateTaskDueDate(with: nil)
    }
    
    private func updateTaskDueDate(with dueDate: Date?) {
        viewModel.task?.dueDate = dueDate
        controller.buildViewModel()
    }
}

// MARK: - Edit Priority
extension TaskDetailViewController {
    
    func changePriorityAction() {
        let storyboard = UIStoryboard(name: StoryboardConstants.storyboard.tasks, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: StoryboardConstants.controller.taskPriority) as? TaskPriorityViewController {
            let bottomSheet = MDCBottomSheetController(contentViewController: viewController)
            bottomSheet.dismissOnDraggingDownSheet = false
            viewController.coordinatorServices = coordinatorServices
            viewController.viewModel.priority = viewModel.priority
            self.navigationController?.present(bottomSheet, animated: true, completion: nil)
            viewController.callBack = { [weak self] (priority) in
                guard let sSelf = self else { return }
                sSelf.updateTaskPriority(with: priority)
            }
        }
    }
    
    private func updateTaskPriority(with priority: Int) {
        viewModel.task?.priority = priority
        controller.buildViewModel()
    }
}

// MARK: - Edit Assignee
extension TaskDetailViewController {
    
    func changeAssigneeAction() {
        let storyboard = UIStoryboard(name: StoryboardConstants.storyboard.tasks, bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: StoryboardConstants.controller.taskAssignee) as? TaskAssigneeViewController {
            viewController.coordinatorServices = coordinatorServices

            let navigationController = UINavigationController(rootViewController: viewController)
            self.present(navigationController, animated: true)
            viewController.callBack = { [weak self] (assignee) in
                guard let sSelf = self else { return }
                sSelf.updateAssignee(with: assignee)
            }
        }
    }
    
    private func updateAssignee(with assignee: TaskNodeAssignee) {
        viewModel.task?.assignee = assignee
        controller.buildViewModel()
    }
}

// MARK: - Edit Task API Calls
extension TaskDetailViewController {
    
    private func showAlertToSaveProgress() {
        let title = LocalizationConstants.General.discard
        let message = LocalizationConstants.EditTask.discardEditTaskAlertMessage

        let confirmAction = MDCAlertAction(title: LocalizationConstants.Dialog.confirmTitle) { [weak self] _ in
            guard let sSelf = self else { return }
            sSelf.backAndRefreshAction(isRefreshList: false)
        }
        confirmAction.accessibilityIdentifier = "confirmActionButton"
        
        let cancelAction = MDCAlertAction(title: LocalizationConstants.General.cancel) { _ in
        }
        cancelAction.accessibilityIdentifier = "cancelActionButton"

        _ = self.showDialog(title: title,
                                       message: message,
                                       actions: [confirmAction, cancelAction],
                                       completionHandler: {})
    }
    
    private func saveEdittedTask() {
        
        var isTaskEdit = false
        if viewModel.isAssigneeChanged() { // call api to change assignee
            isTaskEdit = true
            refreshGroup.enter()
            assignTask()
        }
        if viewModel.isTaskUpdated() { // call api to edit task
            isTaskEdit = true
            refreshGroup.enter()
            editTask()
        }
        
        if isTaskEdit == false {
            self.updateUIAfterTaskEdit()
        }

        refreshGroup.notify(queue: CameraKit.cameraWorkerQueue) {
            AnalyticsManager.shared.didUpdateTaskDetails()
            self.checkForCompleteTaskButton()
            self.viewModel.didRefreshTaskList?()
            self.updateUIAfterTaskEdit()
        }
    }
    
    func assignTask() {
        let userId = String(format: "%d", viewModel.assigneeUserId)
        let params = AssignUserBody(assignee: userId)
        viewModel.assignTask(with: viewModel.taskID, params: params) {[weak self] data, error in
            guard let sSelf = self else { return }
            sSelf.refreshGroup.leave()
        }
    }
    
    func editTask() {
        let priority = String(format: "%d", viewModel.priority)
        let dateString = viewModel.dueDate?.dateString(format: "yyyy-MM-dd") ?? ""
                
        let params = TaskBodyCreate(name: viewModel.taskName,
                                    priority: priority,
                                    dueDate: dateString,
                                    description: viewModel.taskDescription)
        
        viewModel.editTaskDetails(with: viewModel.taskID, params: params) {[weak self] data, error in
            guard let sSelf = self else { return }
            sSelf.refreshGroup.leave()
        }
    }
}

// MARK: - Delete Attachment
extension TaskDetailViewController {
    
    private func didSelectDeleteAttachment(attachment: ListNode) {
        AnalyticsManager.shared.didTapDeleteTaskAttachment()
        viewModel.showDeleteAttachmentAlert(for: attachment, on: self) {[weak self] success in
            guard let sSelf = self else { return }
            AnalyticsManager.shared.apiTracker(name: Event.API.apiDeleteTaskAttachment.rawValue, fileSize: 0, success: success)
            if success {
                sSelf.deleteAttachmentFromList(attachment: attachment)
            }
        }
    }
    
    private func deleteAttachmentFromList(attachment: ListNode) {
        var attachments = viewModel.attachments.value
        if let index = attachments.firstIndex(where: {$0.guid == attachment.guid}) {
            attachments.remove(at: index)
            viewModel.attachments.value = attachments
            controller.buildViewModel()
        }
    }
}

// MARK: - Add Attachment
extension TaskDetailViewController {
    
    private func addAttachmentButtonAction() {
        AnalyticsManager.shared.didTapUploadTaskAttachment()
        
        let actions = ActionsMenuFolderAttachments.actions()
        let actionMenuViewModel = ActionMenuViewModel(menuActions: actions,
                                                      coordinatorServices: coordinatorServices)
        let viewController = ActionMenuViewController.instantiateViewController()
        let bottomSheet = MDCBottomSheetController(contentViewController: viewController)
        viewController.coordinatorServices = coordinatorServices
        viewController.actionMenuModel = actionMenuViewModel
        self.present(bottomSheet, animated: true, completion: nil)
        viewController.didSelectAction = {[weak self] (action) in
            guard let sSelf = self else { return }
            sSelf.handleAction(action: action)
        }
    }
    
    private func handleAction(action: ActionMenu) {
        if action.type.isCreateActions {
            if action.type == .uploadMedia {
                showPhotoLibrary()
            } else if action.type == .createMedia {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self.showCamera()
                })
            } else if action.type == .uploadFiles {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self.showFiles()
                })
            }
        }
    }
    
    func showPhotoLibrary() {
        AnalyticsManager.shared.uploadPhotoforTasks()
        if let presenter = self.navigationController {
            let coordinator = PhotoLibraryScreenCoordinator(with: presenter,
                                                            parentListNode: taskNode(),
                                                            isTaskAttachment: true)
            coordinator.start()
            photoLibraryCoordinator = coordinator
        }
    }
        
    func showCamera() {
        AnalyticsManager.shared.takePhotoforTasks()
        if let presenter = self.navigationController {
            let coordinator = CameraScreenCoordinator(with: presenter,
                                                      parentListNode: taskNode(),
                                                      isTaskAttachment: true)
            coordinator.start()
            cameraCoordinator = coordinator
        }
    }
    
    func showFiles() {
        AnalyticsManager.shared.uploadFilesforTasks()
        if let presenter = self.navigationController {
            let coordinator = FileManagerScreenCoordinator(with: presenter,
                                                            parentListNode: taskNode(),
                                                           isTaskAttachment: true)
            coordinator.start()
            fileManagerCoordinator = coordinator
        }
    }
    
    func taskNode () -> ListNode {
        return ListNode(guid: viewModel.taskID,
                        title: viewModel.taskName ?? "",
                        path: "",
                        nodeType: .folder)
    }
}
