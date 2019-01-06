//
//  GameScene.swift
//  SpaceWar
//
//  Created by Goga Tirkiya on 05/01/2019.
//  Copyright © 2019 Goga Tirkiya. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starSpace: SKEmitterNode!;
    var scoreLabel: SKLabelNode!;
    var player: SKSpriteNode!;
    var menuButton: SKSpriteNode!;
    var gameTimer: Timer!;
    let motionManager = CMMotionManager();
    
    let height: CGFloat = UIScreen.main.bounds.height;
    let width: CGFloat = UIScreen.main.bounds.width;
    let accelerometerUpdateInterval = 0.2;
    var xAccelerate: CGFloat = 0;
    
    let bulletCategory: UInt32 = 0x1 << 0;
    let playerCategory: UInt32 = 0x1 << 1;
    let alienCategory: UInt32 = 0x1 << 2;
    
    var aliensTimeInterval: TimeInterval = 0.75;
    var aliens = ["alien", "alien2", "alien3"];
    var isGameOver = false;
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)";
        }
    }
    
    override func didMove(to view: SKView) {
        configureSelf();
        
        self.addChild(initStarSpace());
        self.addChild(initScoreLabel());
        self.addChild(initPlayer());
        self.addChild(initMenuButton());
        
        if UserDefaults.standard.bool(forKey: "hard") {
            aliensTimeInterval = 0.4;
        }
        
        gameTimer = Timer.scheduledTimer(timeInterval: aliensTimeInterval, target: self,
                                         selector: #selector(addAlien), userInfo: nil, repeats: true);
        motionManager.accelerometerUpdateInterval = accelerometerUpdateInterval;
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (date: CMAccelerometerData?, error: Error?) in
            if let acclerometerDate = date {
                let acceleration = acclerometerDate.acceleration;
                self.xAccelerate = CGFloat(acceleration.x) * 0.75 + self.xAccelerate * 0.25;
            }
        }
    }
    
    override func didSimulatePhysics() {
        let potencialNewPosition = player.position.x + xAccelerate * 60;
        if potencialNewPosition > 0 && potencialNewPosition < width {
            player.position.x = potencialNewPosition;
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var bodyA: SKPhysicsBody = contact.bodyA;
        var bodyB: SKPhysicsBody = contact.bodyB;
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bodyB = contact.bodyA;
            bodyA = contact.bodyB;
        }
        
        if (bodyA.categoryBitMask & alienCategory) != 0 &&
            (bodyB.categoryBitMask & bulletCategory) != 0 {
            killAlien(alien: bodyA.node as! SKSpriteNode,
                      bullet: bodyB.node as! SKSpriteNode);
        } else if (bodyA.categoryBitMask & alienCategory) != 0 &&
            (bodyB.categoryBitMask & playerCategory) != 0 {
            killPlayer(alien: bodyA.node as! SKSpriteNode);
        }
    }
    
    func killAlien(alien: SKSpriteNode, bullet: SKSpriteNode){
        let bang = SKEmitterNode(fileNamed: "Bang");
        bang?.position = alien.position;
        
        self.addChild(bang!);
        self.run(SKAction.playSoundFileNamed("bang", waitForCompletion: false)); // Play bang sound.
        
        bullet.removeFromParent();
        alien.removeFromParent();
        
        self.run(SKAction.wait(forDuration: 2)){
            bang?.removeFromParent();
        }
        score += 5;
        saveScore();
    }
    
    func killPlayer(alien: SKSpriteNode){
        isGameOver = true;
        
        let bangAlien = SKEmitterNode(fileNamed: "Bang");
        bangAlien?.position = alien.position;
        
        let bangPlayer = SKEmitterNode(fileNamed: "Bang");
        bangPlayer?.position = player.position;
        
        self.addChild(bangAlien!);
        self.addChild(bangPlayer!);
        self.run(SKAction.playSoundFileNamed("bang", waitForCompletion: false));
        
        alien.removeFromParent();
        player.removeFromParent();
        
        self.run(SKAction.wait(forDuration: 2)){
            bangAlien?.removeFromParent();
            bangPlayer?.removeFromParent();
        }
        score = 0;
        
        self.run(SKAction.wait(forDuration: 2)){
            self.chaneScene(scene: SKScene(fileNamed: "Menu")!);
        }
    }
    
    @objc func addAlien() {
        aliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: aliens) as! [String];
        
        let alien = SKSpriteNode(imageNamed: aliens[0]); // Get random alien image.
        let availablePositionDiapason = GKRandomDistribution(lowestValue: 10,
                                                             highestValue: Int(width - 10));
        let position = CGFloat(availablePositionDiapason.nextInt());
        
        alien.position = CGPoint(x: position, y: height + alien.size.height);
        alien.name = "alien";
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size);
        alien.physicsBody?.isDynamic = true;
        alien.physicsBody?.categoryBitMask = alienCategory;
        alien.physicsBody?.contactTestBitMask = bulletCategory;
        alien.physicsBody?.collisionBitMask = 0;
        
        self.addChild(alien);
        
        let animationDuration: TimeInterval = 6; // The alien moving speed.
        var actions = [SKAction]();
        actions.append(SKAction.move(to: CGPoint(x: position, y: -alien.size.height),
                                     duration: animationDuration));
        actions.append(SKAction.removeFromParent()); // Remove the alien after going out of the screen.
        
        alien.run(SKAction.sequence(actions)); // Run the alien animation.
    }
    
    func fireBullet() {
        if !isGameOver {
            self.run(SKAction.playSoundFileNamed("shot", waitForCompletion: false)); // Play fire sound.
            
            let bullet = SKSpriteNode(imageNamed: "torpedo"); // Get bullet image.
            bullet.position = CGPoint(x: player.position.x, y: player.position.y + 5);
            
            bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width / 2);
            bullet.physicsBody?.isDynamic = true;
            bullet.physicsBody?.categoryBitMask = bulletCategory;
            bullet.physicsBody?.contactTestBitMask = alienCategory;
            bullet.physicsBody?.collisionBitMask = 0;
            bullet.physicsBody?.usesPreciseCollisionDetection = true; // Make it touchable.
            
            self.addChild(bullet);
            
            let animationDuration: TimeInterval = 0.5; // The bullet speed.
            var actions = [SKAction]();
            
            actions.append(SKAction.move(to: CGPoint(x: player.position.x,
                                                     y: height + bullet.size.height),
                                         duration: animationDuration));
            actions.append(SKAction.removeFromParent());
            
            bullet.run(SKAction.sequence(actions));
        }
    }
    
    func initStarSpace() -> SKEmitterNode{
        starSpace = SKEmitterNode(fileNamed: "StarSpace");
        starSpace.position = CGPoint(x: 0, y: 1472);
        starSpace.advanceSimulationTime(10);
        starSpace.zPosition = -1;
        return starSpace;
    }
    
    func initPlayer() -> SKSpriteNode {
        player = SKSpriteNode(imageNamed: "shuttle");
        player.position = CGPoint(x: width / 2, y: 40);
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2);
        player.physicsBody?.isDynamic = true;
        player.physicsBody?.categoryBitMask = playerCategory;
        player.physicsBody?.contactTestBitMask = alienCategory;
        player.physicsBody?.collisionBitMask = 0;
        player.physicsBody?.usesPreciseCollisionDetection = true; // Make it touchable.
        
        return player;
    }
    
    func initScoreLabel() -> SKLabelNode {
        scoreLabel = SKLabelNode(text: "Score: 0");
        scoreLabel.fontName = "Helvetica-Bold";
        scoreLabel.fontSize = 20;
        scoreLabel.fontColor = UIColor.white;
        scoreLabel.position = CGPoint(x: 50, y: height - 30);
        return scoreLabel;
    }
    
    func initMenuButton() -> SKSpriteNode {
        menuButton = SKSpriteNode(imageNamed: "menuIcon");
        menuButton.position = CGPoint(x: width - 20, y: height - 25);
        menuButton.name = "menuButton";
        menuButton.size = CGSize(width: 20, height: 20);
        return menuButton;
    }
    
    func configureSelf() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0);
        self.physicsWorld.contactDelegate = self;
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first;
        
        if let location = touch?.location(in: self) {
            let nodesArray = self.nodes(at: location);
            
            if nodesArray.first?.name == "menuButton" {
                chaneScene(scene: SKScene(fileNamed: "Menu")!);
            } else {
                fireBullet();
            }
        }
    }
    
    func chaneScene(scene: SKScene){
        if let view = self.view {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill;
            let transition = SKTransition.flipVertical(withDuration: 0.5);
            
            // Present the scene
            view.presentScene(scene, transition: transition);
        }
    }
    
    func saveScore(){
        let userScore = UserDefaults.standard;
        
        if userScore.integer(forKey: "userScore") < score {
            userScore.setValue(score, forKey: "userScore");
            userScore.synchronize();
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        for node in self.children {
            if node.name == "alien" && node.position.y < 0 {
                killPlayer(alien: node as! SKSpriteNode);
            }
        }
    }
}
