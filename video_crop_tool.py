#!/usr/bin/env python3
"""
Универсальный инструмент для обрезки видео
Автоматически определяет и убирает черные границы слева и справа
"""

import cv2
import numpy as np
import os
import argparse
from pathlib import Path
import sys
from typing import Tuple, Optional


class VideoCropper:
    def __init__(self, threshold: float = 30.0):
        """
        Инициализация инструмента для обрезки видео
        
        Args:
            threshold: Порог для определения черных пикселей (0-255)
        """
        self.threshold = threshold
    
    def detect_black_borders(self, frame: np.ndarray) -> Tuple[int, int, int, int]:
        """
        Определяет границы черных областей в кадре
        
        Args:
            frame: Кадр видео (BGR формат)
            
        Returns:
            Tuple с координатами: (left, top, right, bottom)
        """
        # Конвертируем в оттенки серого
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        height, width = gray.shape
        
        # Определяем левую границу
        left = 0
        for x in range(width):
            if np.mean(gray[:, x]) > self.threshold:
                left = x
                break
        
        # Определяем правую границу
        right = width - 1
        for x in range(width - 1, -1, -1):
            if np.mean(gray[:, x]) > self.threshold:
                right = x
                break
        
        # Определяем верхнюю границу
        top = 0
        for y in range(height):
            if np.mean(gray[y, :]) > self.threshold:
                top = y
                break
        
        # Определяем нижнюю границу
        bottom = height - 1
        for y in range(height - 1, -1, -1):
            if np.mean(gray[y, :]) > self.threshold:
                bottom = y
                break
        
        return left, top, right, bottom
    
    def analyze_video_borders(self, video_path: str, sample_frames: int = 10) -> Tuple[int, int, int, int]:
        """
        Анализирует границы видео по нескольким кадрам
        
        Args:
            video_path: Путь к видео файлу
            sample_frames: Количество кадров для анализа
            
        Returns:
            Tuple с координатами границ: (left, top, right, bottom)
        """
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Не удалось открыть видео: {video_path}")
        
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        print(f"Анализ видео: {video_path}")
        print(f"Всего кадров: {total_frames}, FPS: {fps:.2f}")
        
        # Анализируем несколько кадров для определения стабильных границ
        borders_list = []
        frame_interval = max(1, total_frames // sample_frames)
        
        for i in range(0, min(total_frames, sample_frames * frame_interval), frame_interval):
            cap.set(cv2.CAP_PROP_POS_FRAMES, i)
            ret, frame = cap.read()
            if ret:
                borders = self.detect_black_borders(frame)
                borders_list.append(borders)
                print(f"Кадр {i}: границы {borders}")
        
        cap.release()
        
        if not borders_list:
            raise ValueError("Не удалось проанализировать ни одного кадра")
        
        # Вычисляем средние границы
        avg_borders = np.mean(borders_list, axis=0).astype(int)
        print(f"Средние границы: {tuple(avg_borders)}")
        
        return tuple(avg_borders)
    
    def crop_video(self, input_path: str, output_path: str, borders: Optional[Tuple[int, int, int, int]] = None) -> None:
        """
        Обрезает видео по заданным границам
        
        Args:
            input_path: Путь к входному видео
            output_path: Путь к выходному видео
            borders: Границы для обрезки (left, top, right, bottom). Если None, определяются автоматически
        """
        cap = cv2.VideoCapture(input_path)
        if not cap.isOpened():
            raise ValueError(f"Не удалось открыть видео: {input_path}")
        
        # Получаем параметры видео
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        # Определяем границы, если не заданы
        if borders is None:
            print("Определение границ...")
            borders = self.analyze_video_borders(input_path)
        
        left, top, right, bottom = borders
        crop_width = right - left + 1
        crop_height = bottom - top + 1
        
        print(f"Исходный размер: {width}x{height}")
        print(f"Обрезанный размер: {crop_width}x{crop_height}")
        print(f"Границы обрезки: left={left}, top={top}, right={right}, bottom={bottom}")
        
        # Создаем VideoWriter
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(output_path, fourcc, fps, (crop_width, crop_height))
        
        if not out.isOpened():
            raise ValueError(f"Не удалось создать выходной файл: {output_path}")
        
        # Обрабатываем все кадры
        frame_count = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Обрезаем кадр
            cropped_frame = frame[top:bottom+1, left:right+1]
            out.write(cropped_frame)
            
            frame_count += 1
            if frame_count % 100 == 0:
                progress = (frame_count / total_frames) * 100
                print(f"Прогресс: {progress:.1f}% ({frame_count}/{total_frames})")
        
        cap.release()
        out.release()
        
        print(f"Видео успешно обрезано и сохранено: {output_path}")
        print(f"Обработано кадров: {frame_count}")
    
    def process_directory(self, input_dir: str, output_dir: str, file_pattern: str = "*.mp4") -> None:
        """
        Обрабатывает все видео файлы в директории
        
        Args:
            input_dir: Входная директория
            output_dir: Выходная директория
            file_pattern: Паттерн для поиска файлов
        """
        input_path = Path(input_dir)
        output_path = Path(output_dir)
        
        if not input_path.exists():
            raise ValueError(f"Входная директория не существует: {input_dir}")
        
        output_path.mkdir(parents=True, exist_ok=True)
        
        video_files = list(input_path.glob(file_pattern))
        if not video_files:
            print(f"Видео файлы не найдены в {input_dir}")
            return
        
        print(f"Найдено {len(video_files)} видео файлов")
        
        for i, video_file in enumerate(video_files, 1):
            print(f"\n[{i}/{len(video_files)}] Обработка: {video_file.name}")
            
            output_file = output_path / f"cropped_{video_file.name}"
            
            try:
                self.crop_video(str(video_file), str(output_file))
            except Exception as e:
                print(f"Ошибка при обработке {video_file.name}: {e}")


def main():
    parser = argparse.ArgumentParser(description="Инструмент для обрезки черных границ видео")
    parser.add_argument("input", help="Путь к входному видео файлу или директории")
    parser.add_argument("-o", "--output", help="Путь к выходному файлу или директории")
    parser.add_argument("-t", "--threshold", type=float, default=30.0, 
                       help="Порог для определения черных пикселей (0-255, по умолчанию: 30)")
    parser.add_argument("-d", "--directory", action="store_true", 
                       help="Обработать все видео файлы в директории")
    parser.add_argument("-p", "--pattern", default="*.mp4", 
                       help="Паттерн для поиска файлов (по умолчанию: *.mp4)")
    
    args = parser.parse_args()
    
    # Создаем экземпляр инструмента
    cropper = VideoCropper(threshold=args.threshold)
    
    try:
        if args.directory:
            # Обработка директории
            input_dir = args.input
            output_dir = args.output or f"{input_dir}_cropped"
            cropper.process_directory(input_dir, output_dir, args.pattern)
        else:
            # Обработка одного файла
            input_file = args.input
            if not args.output:
                input_path = Path(input_file)
                output_file = input_path.parent / f"cropped_{input_path.name}"
            else:
                output_file = args.output
            
            cropper.crop_video(input_file, str(output_file))
            
    except Exception as e:
        print(f"Ошибка: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
