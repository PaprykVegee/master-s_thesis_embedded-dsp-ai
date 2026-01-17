import torch
from torch import nn
from torch.utils.data import Dataset
from torchvision import transforms

import pytorch_lightning as pl
from torch.utils.data import DataLoader, random_split

import cv2
import numpy as np

from pathlib import Path
import os
import random

class SpektogramDataset(Dataset):
    def __init__(self, folder_path: Path, transform=None):
        self.paths = self._loadpath(folder_path)
        self.transform = transform

    def __len__(self):
        return len(self.paths)

    def __getitem__(self, index):
        spectrogram = cv2.imread(self.paths[index])
        spectrogram = cv2.cvtColor(spectrogram, cv2.COLOR_BGR2RGB)

        label = int(self.paths[index].split("_")[-1].split(".")[0])            

        if self.transform:
            spectrogram = self.transform(spectrogram)

        return spectrogram, label

    def _loadpath(self, folder_path: Path):
        return [
            os.path.join(dirpath, file)
            for dirpath, _, filenames in os.walk(folder_path)
            for file in filenames
        ]
    

class SpektogramDataModule(pl.LightningDataModule):
    def __init__(
        self,
        data_dir: Path,
        transform: transforms = None,
        batch_size: int = 32,
        num_workers: int = 4,
        val_split: float = 0.2,
        test_split: float = 0.1,
    ):
        super().__init__()
        self.data_dir = data_dir
        self.transform = transform
        self.batch_size = batch_size
        self.num_workers = num_workers
        self.val_split = val_split
        self.test_split = test_split

    def setup(self, stage=None):
        full_dataset = SpektogramDataset(
            self.data_dir,
            transform=self.transform
        )

        total_size = len(full_dataset)
        test_size = int(total_size * self.test_split)
        val_size = int(total_size * self.val_split)
        train_size = total_size - val_size - test_size

        self.train_ds, self.val_ds, self.test_ds = random_split(
            full_dataset,
            [train_size, val_size, test_size]
        )

    def train_dataloader(self):
        return DataLoader(
            self.train_ds,
            batch_size=self.batch_size,
            shuffle=True,
            num_workers=self.num_workers,
            pin_memory=True
        )

    def val_dataloader(self):
        return DataLoader(
            self.val_ds,
            batch_size=self.batch_size,
            shuffle=False,
            num_workers=self.num_workers,
            pin_memory=True
        )

    def test_dataloader(self):
        return DataLoader(
            self.test_ds,
            batch_size=self.batch_size,
            shuffle=False,
            num_workers=self.num_workers,
            pin_memory=True
        )