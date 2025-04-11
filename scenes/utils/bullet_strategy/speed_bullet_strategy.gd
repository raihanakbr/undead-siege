class_name SpeedBulletStrategy
extends BaseBulletStrategy

func apply_upgrade(bullet: Bullet):
	bullet.speed *= 1.5
	bullet.sprite.frame = 27
