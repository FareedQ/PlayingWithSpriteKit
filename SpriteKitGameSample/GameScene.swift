import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player")
    var projectiles = [SKSpriteNode]()
    var monstersDestroyed = 0
    var shots = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.white
        player.size = CGSize(width: 52, height: 80)
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/4)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        player.physicsBody?.collisionBitMask = PhysicsCategory.None
        player.physicsBody?.usesPreciseCollisionDetection = true
        
        
        projectiles = [SKSpriteNode(), SKSpriteNode(), SKSpriteNode()]
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: "monster")
        monster.size = CGSize(width: 52, height: 40)
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // Add the monster to the scene
        addChild(monster)
        
        monster.physicsBody = SKPhysicsBody(circleOfRadius: monster.size.width/4) // 1
        monster.physicsBody?.isDynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
        
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        let offset = player.position - monster.position
        let direction = offset.normalized()
        let shootAmount = direction * 1000
        let realDest = shootAmount + monster.position
        let actionMove = SKAction.move(to: realDest, duration: TimeInterval(actualDuration))
        
//        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        
        let actionMoveDone = SKAction.removeFromParent()
        let loseAction = SKAction.run() {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        // Loop over all nodes in the scene
        self.enumerateChildNodes(withName: "projectlie") {
            node, stop in
            if (node is SKSpriteNode) {
                let sprite = node as! SKSpriteNode
                // Check if the node is not in the scene
                if (sprite.position.x < -sprite.size.width/2.0 || sprite.position.x > self.size.width+sprite.size.width/2.0
                    || sprite.position.y < -sprite.size.height/2.0 || sprite.position.y > self.size.height+sprite.size.height/2.0) {
                    sprite.removeFromParent()
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for i in 0...2 {
            if !self.children.contains(projectiles[i]) {
                projectiles[i] = SKSpriteNode(imageNamed: "projectile")
            } else {
                continue
            }
            
            run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
            
            
            guard let touch = touches.first else {
                return
            }
            let touchLocation = touch.location(in: self)
            
            projectiles[i].position = player.position
            
            addChild(projectiles[i])
            
            
            projectiles[i].physicsBody = SKPhysicsBody(circleOfRadius: projectiles[i].size.width/2)
            projectiles[i].physicsBody?.isDynamic = true
            projectiles[i].physicsBody?.categoryBitMask = PhysicsCategory.Projectile
            projectiles[i].physicsBody?.contactTestBitMask = PhysicsCategory.Monster
            projectiles[i].physicsBody?.collisionBitMask = PhysicsCategory.None
            projectiles[i].physicsBody?.usesPreciseCollisionDetection = true
            
            
            let offset = touchLocation - projectiles[i].position
            let direction = offset.normalized()
            let shootAmount = direction * 1000
            let realDest = shootAmount + projectiles[i].position
            
            let actionMove = SKAction.move(to: realDest, duration: 2.0)
            let actionMoveDone = SKAction.removeFromParent()
            projectiles[i].run(SKAction.sequence([actionMove, actionMoveDone]))
            return
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask == PhysicsCategory.Monster) &&
            (secondBody.categoryBitMask == PhysicsCategory.Projectile)) {
            guard let firstBodyNode = firstBody.node as? SKSpriteNode,
                let secondBodyNode = secondBody.node as? SKSpriteNode else {
                    return
            }
            projectileDidCollideWithMonster(projectile: firstBodyNode, monster: secondBodyNode)
        } else if ((firstBody.categoryBitMask == PhysicsCategory.Monster) &&
        (secondBody.categoryBitMask == PhysicsCategory.Player)) {
            monsterDidCollideWithPlayer()
        }
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        projectile.removeFromParent()
        monster.removeFromParent()
        monstersDestroyed += 1
        if (monstersDestroyed > 30) {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    
    
    func monsterDidCollideWithPlayer() {
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        let gameOverScene = GameOverScene(size: self.size, won: false)
        self.view?.presentScene(gameOverScene, transition: reveal)
    }
}
