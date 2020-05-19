//
//  FeedViewController.swift
//  Finstagram
//
//  Created by user169361 on 5/9/20.
//  Copyright © 2020 user169361. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

//create UIRefreshControl as an instance variable because it will be needed to access the stop loading feature
var refreshControl: UIRefreshControl!

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
   

    @IBOutlet weak var tableView: UITableView!
    
    let commentBar = MessageInputBar()
    
    //sets the comment text bar not to be shown by default
    var showsCommentBar = false
    
    var posts = [PFObject]()
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //enables the keyboard to be dismissed by scrolling
        tableView.keyboardDismissMode = .interactive
        
        //grab  the post office notification center
        //I want to observe an event (The keyboard hiding)
        //on myself call this function
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        
        // Do any additional setup after loading the view.
    }
    
    //event for when the comment bar is clicked
    @objc func keyboardWillBeHidden(note: Notification){
        //everytime the keyboard is dismissed, clear the text field
        commentBar.inputTextView.text = nil
        
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    //allow the incorporation of a comment text bar at the bottom of the screen
    override var inputAccessoryView: UIView?{
        return commentBar
    }
    
    //initiates access to keyboard for comment text bar
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query =  PFQuery(className:"Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
        
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
          comment["post"] = selectedPost
          comment["author"] = PFUser.current()//author is the current user signed in
          
          selectedPost.add(comment, forKey: "comments")
          
          selectedPost.saveInBackground { (success, error) in
              if success{
                  print("Comment saved")
              } else {
                  print("Error saving comment")
              }
          }
        //to trigger newly created comments to appear immediately
        tableView.reloadData()
        
        //clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
 
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let post = posts[section] //grab the post
        //grab the comments and declare them as an array of PFObject, then use a nil coalescing operator (which says whatever is on the left if nil set it to this
        let comments = (post["comments"] as? [(PFObject)]) ?? []
        
        return comments.count + 2//
        
    }
    
    //lets give each post its own section, each section can have a different number of rows
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return posts.count// there is many sections as there is posts
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.section]
        
        let comments = (post["comments"] as? [(PFObject)]) ?? []
        
        if indexPath.row == 0 {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
           as! PostCell
        
        let user = post["author"] as! PFUser
        
            cell.usernameLabel.text = user.username
            
            cell.captionLabel.text = (post["caption"] as! String)
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string:urlString)!
            
            cell.photoView.af_setImage(withURL: url)
            
            return cell
        } else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            let comment = comments[indexPath.row - 1]
            
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            
            cell.nameLabel.text = user.username
            
            return cell
        } else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
    
    //every time the user clicks on the picture this function is called
    //this allows us to add comments to posts
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //choose post to add comment to
        let post = posts[indexPath.section]
        
        //create your comment object
        let comments = (post["comments"] as? [PFObject]) ??
           []
        
        //if we are at the last cell then display the comment
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            
            //then allows the keyboard to be displayed as well
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
        
        /*
  
       */
    }
    
    func loadMorePosts(){
        
    }
    
    
    func run(after wait: TimeInterval, closure: @escaping () -> Void){
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: DispatchTime.now() + wait, execute: closure)
    }
    
    
    @objc func onRefresh(){
        run (after: 2){
            refreshControl.endRefreshing()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onLogoutButton(_ sender: Any) {
        //parse cache is cleared and user is considered not logged in anymore
        PFUser.logOut()
        
        //grab storyboard and instantiate it
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        
        //set the window that will be transitioned to on logout
        // let delegate = UIApplication.shared.delegate as! AppDelegate
        // delegate.window?.rootViewController = loginViewController
        
        let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
        
        sceneDelegate.window?.rootViewController = loginViewController
    }
    
}
