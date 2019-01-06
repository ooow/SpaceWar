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
    var gameTimer: Timer!;
    let motionManager = CMMotionManager();

    let height: CGFloat = 667;
    let width: CGFloat = 375;
    let accelerometerUpdateInterval = 0.2;
    var xAccelerate: CGFloat = 0;
    
    let alienCategory: UInt32 = 0x1 << 1;
    let bulletCategory: UInt32 = 0x1 << 0;
    var aliensTimeInterval: TimeInterval = 0.75;
    var aliens = ["alien", "alien2", "alien3"];
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
        if potencialNewPosition > -width && potencialNewPosition < width {
            player.position.x = potencialNewPosition;
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var bulletBody: SKPhysicsBody = contact.bodyB;
        var alienBody: SKPhysicsBody = contact.bodyA;
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bulletBody = contact.bodyA; // Is a bullet.
            alienBody = contact.bodyB; // Is a alien.
        }
    
        if (alienBody.categoryBitMask & alienCategory) != 0 &&
            (bulletBody.categoryBitMask & bulletCategory) != 0 {
            collisionElements(alien: alienBody.node as! SKSpriteNode,
                              bullet: bulletBody.node as! SKSpriteNode);
        }
    }
    
    func collisionElements(alien: SKSpriteNode, bullet: SKSpriteNode){
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
    }
    
    @objc func addAlien() {
        aliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: aliens) as! [String];
        
        let alien = SKSpriteNode(imageNamed: aliens[0]); // Get random alien image.
        let availableWidth = Int(width - 40);
        let availableHeight = height + 100;
        let availablePositionDiapason = GKRandomDistribution(lowestValue: -availableWidth,
                                                             highestValue: availableWidth);
        let position = CGFloat(availablePositionDiapason.nextInt());
        
        alien.position = CGPoint(x: position, y: availableHeight);
        alien.setScale(2);
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size);
        alien.physicsBody?.isDynamic = true;
        alien.physicsBody?.categoryBitMask = alienCategory;
        alien.physicsBody?.contactTestBitMask = bulletCategory;
        alien.physicsBody?.collisionBitMask = 0;
        
        self.addChild(alien);
        
        let animationDuration: TimeInterval = 6; // The alien moving speed.
        var actions = [SKAction]();
        actions.append(SKAction.move(to: CGPoint(x: position, y: -availableHeight),
                                     duration: animationDuration));
        actions.append(SKAction.removeFromParent()); // Remove the alien after going out of the screen.
        
        alien.run(SKAction.sequence(actions)); // Run the alien animation.
    }
    
    func fireBullet() {
        self.run(SKAction.playSoundFileNamed("shot", waitForCompletion: false)); // Play fire sound.
        
        let bullet = SKSpriteNode(imageNamed: "torpedo"); // Get bullet image.
        bullet.position = CGPoint(x: player.position.x, y: player.position.y + 5);
        bullet.setScale(2);
        
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
    
    func initStarSpace() -> SKEmitterNode{
        starSpace = SKEmitterNode(fileNamed: "StarSpace");
        starSpace.position = CGPoint(x: 0, y: 1472);
        starSpace.advanceSimulationTime(10);
        starSpace.zPosition = -1;
        return starSpace;
    }
    
    func initPlayer() -> SKSpriteNode {
        player = SKSpriteNode(imageNamed: "shuttle");
        player.position = CGPoint(x: 0, y: -height / 2 - 150);
        player.setScale(2);
        return player;
    }
    
    func initScoreLabel() -> SKLabelNode {
        scoreLabel = SKLabelNode(text: "Score: 0");
        scoreLabel.fontName = "AmericanTypewritter-Bold";
        scoreLabel.fontSize = 36;
        scoreLabel.fontColor = UIColor.white;
        scoreLabel.position = CGPoint(x: -width + 80, y: height - 40);
        return scoreLabel;
    }
    
    func configureSelf() {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0);
        self.physicsWorld.contactDelegate = self;
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet();
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
