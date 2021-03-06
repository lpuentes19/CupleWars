//
//  PostsTableViewCell.swift
//  CupleWars
//
//  Created by Luis Puentes on 9/15/17.
//  Copyright © 2017 LuisPuentes. All rights reserved.
//

import UIKit

class PostsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var hisCountLabel: UILabel!
    @IBOutlet weak var herCountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var hisLikeImageView: UIImageView!
    @IBOutlet weak var herLikeImageView: UIImageView!
    @IBOutlet weak var flagButton: UIButton!
    
    var delegate: PostsTableViewCellDelegate?
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    var user: UserModel? {
        didSet {
            setupUserInfo()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextView()
        
        let tapGestureForHisLikeImage = UITapGestureRecognizer(target: self, action: #selector(self.hisLikeImageTapped))
        hisLikeImageView.addGestureRecognizer(tapGestureForHisLikeImage)
        hisLikeImageView.isUserInteractionEnabled = true
        
        let tapGestureForHerLikeImage = UITapGestureRecognizer(target: self, action: #selector(self.herLikeImageTapped))
        herLikeImageView.addGestureRecognizer(tapGestureForHerLikeImage)
        herLikeImageView.isUserInteractionEnabled = true
    }
    
    func setupTextView() {
        postTextView.layer.cornerRadius = 5
    }
    
    func setupUserInfo() {
        guard let user = user else { return }
        usernameLabel.text = user.username
    }
    
    func updateViews() {
        guard let post = post else { return }
        
        postTextView.text = post.postText
        updateHisLike(post: post)
        updateHerLike(post: post)
        
      // This method converts Firebase Timestamp to a Date
        API.Post.ref_Posts.child(post.postID!).child("timestamp").observe(.value, with: { (snapshot) in
            if let timestamp = snapshot.value as? TimeInterval {
                post.date = Date(timeIntervalSince1970: timestamp / 1000)
                let formatter = DateFormatter()
                formatter.dateFormat = "dd-MMM-yyyy"
                let date = formatter.string(from: post.date as Date)
                
                self.dateLabel.text = "\(date)"
            }
        })
        
        // Methods below checks for changes in his and her likes and updates them in real time
//        API.Post.observeHisLikeCount(withID: post.postID!) { (value) in
//            if value == 1 {
//                self.hisCountLabel.text = "\(value) Like"
//            } else {
//                if value != 0 {
//                    self.hisCountLabel.text = "\(value) Likes"
//                }
//            }
//        }
//
//        API.Post.observeHerLikeCount(withID: post.postID!) { (value) in
//            if value == 1 {
//                self.herCountLabel.text = "\(value) Like"
//            } else {
//                if value != 0 {
//                    self.herCountLabel.text = "\(value) Likes"
//                }
//            }
//        }
    }
    
    func updateHisLike(post: Post) {
        let imageName = post.hisLikes == nil || !post.isHisLiked! ? "man" : "manFilled"
        hisLikeImageView.image = UIImage(named: imageName)
        
        guard let count = post.hisLikeCount else { return }
        if count == 1 {
            hisCountLabel.text = "\(count) Like"
        } else if count != 0 {
            hisCountLabel.text = "\(count) Likes"
        } else {
            if count == 0 {
                hisCountLabel.text = "0 Likes"
            }
        }
    }
    
    func updateHerLike(post: Post) {
        let imageName = post.herLikes == nil || !post.isHerLiked! ? "women" : "womanFilled"
        herLikeImageView.image = UIImage(named: imageName)
        
        guard let count = post.herLikeCount else { return }
        if count == 1 {
            herCountLabel.text = "\(count) Like"
        } else if count != 0 {
            herCountLabel.text = "\(count) Likes"
        } else {
            if count == 0 {
                herCountLabel.text = "0 Likes"
            }
        }
    }
    
    @objc func hisLikeImageTapped() {
        API.Post.incrementLikesForHim(postID: post!.postID!, onSuccess: { (post) in
            self.updateHisLike(post: post)
            self.post?.hisLikes = post.hisLikes
            self.post?.isHisLiked = post.isHisLiked
            self.post?.hisLikeCount = post.hisLikeCount
        }) { (errorMessage) in
            //ProgressHUD.showError(errorMessage)
        }
    }
    
    @objc func herLikeImageTapped() {
        API.Post.incrementLikesForHer(postID: post!.postID!, onSuccess: { (post) in
            self.updateHerLike(post: post)
            self.post?.herLikes = post.herLikes
            self.post?.isHerLiked = post.isHerLiked
            self.post?.herLikeCount = post.herLikeCount
        }) { (errorMessage) in
            //ProgressHUD.showError(errorMessage)
        }
    }

    @IBAction func flagButtonTapped(_ sender: Any) {
        
        if let topController = UIApplication.topViewController() {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let flagAsInnappropriate = UIAlertAction(title: "Report as innapropriate", style: .destructive) { (_) in
                
                // Creating a alertcontroller if they select to flag post, to let the user know they successfully did it
                let successAlertController = UIAlertController(title: "Success", message: "You have successfully reported this post. It will be reviewed shortly.", preferredStyle: .alert)
                
                let okAlert = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    API.Report.observeReports(user: self.post!.userID!, postID: self.post!.postID!)
                })
                
                successAlertController.addAction(okAlert)
                topController.present(successAlertController, animated: true, completion: nil)
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            // Action sheet alertcontroller actions
            alertController.addAction(flagAsInnappropriate)
            alertController.addAction(cancel)
            
            // If I ever decide to release this app for the iPad, this ensures the Alert Controllers are presented
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                alertController.popoverPresentationController?.sourceView = sender as? UIView
                alertController.popoverPresentationController?.sourceRect = (sender as AnyObject).bounds
            }
            topController.present(alertController, animated: true, completion: nil)
        }
    }
}

protocol PostsTableViewCellDelegate {
}
