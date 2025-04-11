class_name PiercingBulletStrategy
extends BaseBulletStrategy

func apply_upgrade(bullet: Bullet):
	# Increase piercing
	bullet.piercing += 3
	
	# Add visual effect with yellow theme
	var effect = PiercingEffect.new()
	bullet.add_child(effect)
	
	# Apply a subtle yellow tint to the bullet itself
	bullet.modulate = Color(1.2, 1.2, 0.8)  # Subtle yellow glow

# Inner class that handles all effects with its own process method
class PiercingEffect extends Node2D:
	var trail: Line2D
	var particles: GPUParticles2D
	var trail_points = []
	var max_points = 15
	
	func _ready():
		
		# Create a more elegant trail
		trail = Line2D.new()
		trail.width = 2.5  # Thinner, more elegant width
		trail.default_color = Color(1.0, 0.9, 0.4, 0.6)  # Golden yellow, semi-transparent
		trail.z_index = -1
		
		# Make trail fade out
		trail.gradient = Gradient.new()
		trail.gradient.add_point(0.0, Color(1.0, 0.9, 0.3, 0.0))  # Start transparent
		trail.gradient.add_point(0.5, Color(1.0, 0.9, 0.3, 0.6))  # Middle visible
		trail.gradient.add_point(1.0, Color(1.0, 0.7, 0.1, 0.8))  # End more saturated
		
		add_child(trail)
		
		# Create particles
		particles = GPUParticles2D.new()
		particles.position = Vector2(0, 0)  # At bullet position
		
		var material = ParticleProcessMaterial.new()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		material.direction = Vector3(-1, 0, 0)  # Emit backward from bullet
		material.spread = 10.0  # Tighter spread
		material.gravity = Vector3(0, 0, 0)
		material.initial_velocity_min = 10.0  # Moderate speed
		material.initial_velocity_max = 20.0  # Moderate speed
		material.scale_min = 0.8  # Smaller particles
		material.scale_max = 1.5  # Smaller particles
		material.color = Color(1.0, 0.9, 0.3, 0.6)  # Golden yellow
		
		particles.process_material = material
		particles.amount = 15  # Fewer particles
		particles.lifetime = 0.6  # Medium lifetime
		particles.local_coords = true
		particles.emitting = true
		
		# Create a small soft glow texture
		particles.texture = _create_glow_dot()
		
		add_child(particles)
	
	func _process(delta):
		# Store current global position
		trail_points.append(global_position)
		
		# Limit number of points
		if trail_points.size() > max_points:
			trail_points.remove_at(0)
		
		# Update trail to follow behind bullet
		trail.clear_points()
		for i in range(trail_points.size()):
			# Convert global positions to local coordinates
			var local_pos = to_local(trail_points[i])
			trail.add_point(local_pos)
	
	func _create_glow_dot() -> Texture2D:
		# Create a soft glow dot texture (8x8)
		var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))  # Start transparent
		
		# Draw a soft glow
		for y in range(8):
			for x in range(8):
				var dist = Vector2(x - 4, y - 4).length()
				if dist <= 4:
					# Soft falloff
					var alpha = pow(1.0 - (dist / 4), 2) * 0.7
					img.set_pixel(x, y, Color(1.0, 0.9, 0.6, alpha))
		
		return ImageTexture.create_from_image(img)
