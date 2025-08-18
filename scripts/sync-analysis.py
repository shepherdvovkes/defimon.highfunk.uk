#!/usr/bin/env python3

# Текущие данные (после перезагрузки)
current = 0x4e5dd6
highest = 0x1609928
starting = 0x49edaa

# Предыдущие данные (до перезагрузки)
prev_current = 0x49e3e2
prev_highest = 0x16098ef
prev_starting = 0x49d309

print("=== АНАЛИЗ ИЗМЕНЕНИЙ В СИНХРОНИЗАЦИИ ===")
print()

print("📊 ТЕКУЩИЙ СТАТУС (после перезагрузки):")
print(f"   Текущий блок: {current:,} (0x{current:x})")
print(f"   Высший блок:  {highest:,} (0x{highest:x})")
print(f"   Стартовый:    {starting:,} (0x{starting:x})")

print()
print("📊 ПРЕДЫДУЩИЙ СТАТУС (до перезагрузки):")
print(f"   Текущий блок: {prev_current:,} (0x{prev_current:x})")
print(f"   Высший блок:  {prev_highest:,} (0x{prev_highest:x})")
print(f"   Стартовый:    {prev_starting:,} (0x{prev_starting:x})")

print()
print("🔄 АНАЛИЗ ИЗМЕНЕНИЙ:")

# Изменения в блоках
blocks_synced_now = current - starting
blocks_synced_before = prev_current - prev_starting
blocks_remaining_now = highest - current
blocks_remaining_before = prev_highest - prev_current

print(f"   Блоков синхронизировано:")
print(f"     Сейчас:     {blocks_synced_now:,}")
print(f"     Раньше:     {blocks_synced_before:,}")
print(f"     Разница:    {blocks_synced_now - blocks_synced_before:,}")

print()
print(f"   Блоков осталось:")
print(f"     Сейчас:     {blocks_remaining_now:,}")
print(f"     Раньше:     {blocks_remaining_before:,}")
print(f"     Разница:    {blocks_remaining_before - blocks_remaining_now:,}")

print()
print("📈 ПРОГРЕСС СИНХРОНИЗАЦИИ:")
progress_now = (current - starting) * 100 / (highest - starting) if (highest - starting) > 0 else 0
progress_before = (prev_current - prev_starting) * 100 / (prev_highest - prev_starting) if (prev_highest - prev_starting) > 0 else 0

print(f"   Сейчас:       {progress_now:.4f}%")
print(f"   Раньше:       {progress_before:.4f}%")
print(f"   Улучшение:    {progress_now - progress_before:.4f}%")

print()
print("🚀 ВЫВОДЫ:")
if blocks_synced_now > blocks_synced_before:
    print("   ✅ Синхронизация ПРОДОЛЖАЕТСЯ - прогресс есть!")
    print(f"   📊 Синхронизировано дополнительно: {blocks_synced_now - blocks_synced_before:,} блоков")
else:
    print("   ⚠️  Синхронизация НЕ ПРОДВИНУЛАСЬ")

if blocks_remaining_now < blocks_remaining_before:
    print("   📉 Осталось меньше блоков - это хорошо!")
else:
    print("   📈 Осталось больше блоков - возможно, сеть выросла")

print()
print("💡 РЕКОМЕНДАЦИИ:")
print("   1. Проверить количество активных пиров")
print("   2. Мониторить скорость синхронизации")
print("   3. Убедиться, что SWAP файл работает корректно")
