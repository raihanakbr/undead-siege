# Modifikasi Fitur

## 1. Piercing Bullet Enhancement
- **Perubahan**: Sekarang hanya peluru piercing yang dapat menembus tembok
- **Detail**: Peluru biasa akan terhenti saat mengenai tembok, sementara peluru dengan upgrade piercing dapat melewati obstacles
- **Implementasi**: Sistem collision layer dimodifikasi untuk peluru piercing

## 2. Cheat Code System
- **Fitur Baru**: Tambahan cheat code untuk restore health penuh
- **Cara Penggunaan**: Tekan angka "12345" secara berurutan dengan cepat
- **Efek**: Mengembalikan health player ke maksimum
- **Timeout**: Sequence akan reset otomatis setelah 3 detik jika tidak ada input

## Technical Details

### Piercing Bullet
```gdscript
# Hanya piercing bullet yang disable wall collision
bullet.set_collision_mask_value(5, false)
```

### Cheat Code Implementation
```gdscript
# Sequence detection dengan timeout
var cheat_sequence = "12345"
```