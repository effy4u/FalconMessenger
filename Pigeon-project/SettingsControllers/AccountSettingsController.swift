//
//  AccountSettingsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/5/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


class AccountSettingsController: UITableViewController {

  let userProfileContainerView = UserProfileContainerView()
  let userProfilePictureOpener = UserProfilePictureOpener()
  
  let accountSettingsCellId = "userProfileCell"

  var firstSection = [( icon: UIImage(named: "Notification") , title: "Notifications and sounds" ),
                      ( icon: UIImage(named: "ChangeNumber") , title: "Change number"),
                      ( icon: UIImage(named: "Storage") , title: "Data and storage")]
  
  var secondSection = [( icon: UIImage(named: "Legal") , title: "Legal"),
                       ( icon: UIImage(named: "Logout") , title: "Log out")]
  
  let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBarButtonPressed))
  let doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action:  #selector(doneBarButtonPressed))
  
  var currentName = String()
  

  override func viewDidLoad() {
     super.viewDidLoad()
    
    title = "Settings"
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    view.backgroundColor = UIColor.white
    tableView = UITableView(frame: tableView.frame, style: .grouped)
    
    configureTableView()
    configureContainerView()
    listenChanges()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if userProfileContainerView.phone.text == "" {
      listenChanges()
    }
  }
  
  
  func listenChanges() {
    
    if let currentUser = Auth.auth().currentUser?.uid {
      
      let photoURLReference = Database.database().reference().child("users").child(currentUser).child("photoURL")
      photoURLReference.observe(.value, with: { (snapshot) in
        if let url = snapshot.value as? String {
          self.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: url) , placeholderImage: nil, options: [.highPriority, .continueInBackground], completed: {(image, error, cacheType, url) in
            if error != nil {
              //basicErrorAlertWith(title: "Error loading profile picture", message: "It seems like you are not connected to the internet.", controller: self)
            }
          })
        }
      })
      
      let nameReference = Database.database().reference().child("users").child(currentUser).child("name")
      nameReference.observe(.value, with: { (snapshot) in
        if let name = snapshot.value as? String {
          self.userProfileContainerView.name.text = name
          self.currentName = name
        }
      })
      
      let phoneNumberReference = Database.database().reference().child("users").child(currentUser).child("phoneNumber")
      phoneNumberReference.observe(.value, with: { (snapshot) in
        if let phoneNumber = snapshot.value as? String {
          self.userProfileContainerView.phone.text = phoneNumber
        }
      })
    }
  }

  
  fileprivate func configureTableView() {
    
    tableView.separatorStyle = .none
    tableView.backgroundColor = UIColor.white
    tableView.tableHeaderView = userProfileContainerView
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(AccountSettingsTableViewCell.self, forCellReuseIdentifier: accountSettingsCellId)
  }
  
  fileprivate func configureContainerView() {
    
    userProfileContainerView.name.addTarget(self, action: #selector(nameDidBeginEditing), for: .editingDidBegin)
    userProfileContainerView.name.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
    userProfileContainerView.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
    userProfileContainerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 300)
  }
  
  @objc fileprivate func openUserProfilePicture() {
    
    userProfilePictureOpener.userProfileContainerView = userProfileContainerView
    userProfilePictureOpener.controllerWithUserProfilePhoto = self
    
    cancelBarButtonPressed()
    userProfilePictureOpener.openUserProfilePicture()
  }
  
  
  func logoutButtonTapped () {
  
    let firebaseAuth = Auth.auth()
    removeUserNotificationToken()
    
    do {
      try firebaseAuth.signOut()
  
    } catch let signOutError as NSError {
      basicErrorAlertWith(title: "Error signing out", message: signOutError.localizedDescription, controller: self)
      return
    }
    
    UIApplication.shared.applicationIconBadgeNumber = 0
    
    let destination = OnboardingController()
    
    let newNavigationController = UINavigationController(rootViewController: destination)
    newNavigationController.navigationBar.shadowImage = UIImage()
    newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
    
    newNavigationController.navigationBar.isTranslucent = false
    newNavigationController.modalTransitionStyle = .crossDissolve
    
    self.present(newNavigationController, animated: true, completion: {
       self.tabBarController?.selectedIndex = tabs.chats.rawValue
    })
  }
  
  func removeUserNotificationToken() {
    
    let userReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("notificationTokens")
    userReference.removeValue()
  }
  
}



extension AccountSettingsController {
  
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: accountSettingsCellId, for: indexPath) as! AccountSettingsTableViewCell
    cell.accessoryType = .disclosureIndicator
    if indexPath.section == 0 {
      
      cell.icon.image = firstSection[indexPath.row].icon
      cell.title.text = firstSection[indexPath.row].title
    }
    
    if indexPath.section == 1 {
      
      cell.icon.image = secondSection[indexPath.row].icon
      cell.title.text = secondSection[indexPath.row].title
      
      if indexPath.row == 1 {
        cell.accessoryType = .none
      }
    }
    return cell
  }
  
 override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 0 {
      
      if indexPath.row == 0 {
        let destination = NotificationsAndSoundsTableViewController()
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
      }
      
      if indexPath.row == 1 {
        let destination = UINavigationController(rootViewController: ChangeNumberEnterPhoneNumberController())
        destination.hidesBottomBarWhenPushed = true
        destination.navigationBar.isTranslucent = false
        self.present(destination, animated: true, completion: nil)
      }
      
      if indexPath.row == 2 {
        let destination = StorageTableViewController()
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination, animated: true)
      }
    }
      
      if indexPath.section == 1 {
        
        if indexPath.row == 0 {
          let destination = LegalTableViewController()
          destination.hidesBottomBarWhenPushed = true
          self.navigationController?.pushViewController(destination, animated: true)
        }
        
        if indexPath.row == 1 {
          logoutButtonTapped()
        }
      }
    
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  
 override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  
override  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if section == 0 {
      return firstSection.count
    }
    if section == 1 {
      return secondSection.count
    } else {
      
      return 0
    }
  }
}
