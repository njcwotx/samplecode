import math
import random
import pygame pygame import mixer

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