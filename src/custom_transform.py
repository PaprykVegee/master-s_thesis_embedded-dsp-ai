import torch
from torch import nn

import random

class ShuffleChannels:
    def __init__(self, p=1.0):
        self.p = p  

    def __call__(self, x):
        if random.random() < self.p:
            if x.ndim != 3:
                return x 

            C, H, W = x.shape
            if C != 3:
                return x  

            ch_list = [0, 1, 2]
            random.shuffle(ch_list)
            x = x[ch_list, :, :]  
        return x
