import math
import random
import pygame
from pygame import mixer

#initialize pygame
pygame.init()

#create the screen
screen = pygame.display.set_mode((800,500))

#Background
background=pygame.image.load('background.png')

#Sound
mixer.music.load('background.wav')
mixer.music.play(-1)

#Caption and Icon
pygame.display.set_caption("Space Invader")
icon=pygame.image.load('ufo.png')
pygame.dispaly.set_icon(icon)

#Player
playerimg = pygame.image.load('player.png')
playerX = 370
playerY = 380
playerX_change = 0

#Enemy
enemyImg=[]
enemyX = []
enemyY = []
enemyX_change = []
enemyY_change = []
num_of_enemies = 6

for i in range(num_of_enemies):
    enemyImg.append(pygame.image.load('enemy.png'))
    enemyX.append(random.randint(0,736))
    enemyY.append(random.randint(50,150))
    enemyX_change.append(4)
    enemyY_change.append(40)

#Bullet
#Ready- You cant see bullet on screen
#Fire-the bullet is currently moving

bulletImg = pygame.image.load("bullet.png")
bulletX = 0
bulletY = 380
bulletX_change = 0
bulletY_change = 10
bullet_state = "ready"

#Score
score_value = 0
font=pygame.font.Font('freesansbold.ttf',32)
textX = 10
textY = 10

#GameOver
over_font = pygame.font.Font('freesansbold.ttf', 64)

#Functions

def show_score(x,y):
    score=font.render("Score:" + str(score_value),True,(255,255,255))
    screen.blit(score,(200,250))

def game_over_text():
    over_text = over_font.render("GAME OVER", True,(255,255,255))
    screen.blit(over_text, (200,250))

