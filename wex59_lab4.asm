# Weini Xie He
# wex59

.include "lab4_include.asm"

# maximum number of particles that can be around at one time
.eqv MAX_PARTICLES 100

# limits on emitter position
.eqv EMITTER_X_MIN 0
.eqv EMITTER_X_MAX 63
.eqv EMITTER_Y_MIN 0
.eqv EMITTER_Y_MAX 63

# limits on particle positions
.eqv PARTICLE_X_MIN 0
.eqv PARTICLE_X_MAX 6399 # "63.99"
.eqv PARTICLE_Y_MIN 0
.eqv PARTICLE_Y_MAX 6399 # "63.99"

# gravitational constant
.eqv GRAVITY 7 # "0.07"

# velocity randomization constants
.eqv VEL_RANDOM_MAX 70 # "0.70"
.eqv VEL_RANDOM_MAX_OVER_2 35 # "0.35"
# some assemblers let you do calculations on constants, but not the one in MARS! :/
# hence the awkward OVER_2 constant here

.data
	# position of the emitter (which the user has control over)
	emitter_x: .word 32
	emitter_y: .word 5

	# parallel arrays of particle properties
	particle_active: .byte 0:MAX_PARTICLES # "boolean" (0 or 1)
	particle_x:      .half 0:MAX_PARTICLES # unsigned
	particle_y:      .half 0:MAX_PARTICLES # unsigned
	particle_vx:     .half 0:MAX_PARTICLES # signed
	particle_vy:     .half 0:MAX_PARTICLES # signed
.text

.globl main
main:
	# when done at the beginning of the program, clears the display
	# because the display RAM is all 0s (black) right now.
	jal display_update_and_clear

	_loop:
		jal check_input
		jal update_particles
		jal draw_particles
		jal draw_emitter

		jal display_update_and_clear
		jal sleep
	j _loop

	# exit (should never get here, but I'm superstitious okay)
	li v0, 10
	syscall

#-----------------------------------------

# returns the array index of the first free particle slot,
# or -1 if there are no free slots.
find_free_particle:
push ra
	# use v0 as the loop index; loop until the particle at that index is not active
	li v0, 0
	_loop:
		lb t0, particle_active(v0)
		beq t0, 0, _return
	add v0, v0, 1
	blt v0, MAX_PARTICLES, _loop

	# no free particles found!
	li v0, -1
_return:
pop ra
jr ra

#-----------------------------------------

draw_emitter:
push ra
	lw a0, emitter_x
	lw a1, emitter_y
	li a2, COLOR_WHITE
	jal display_set_pixel

pop ra
jr ra

check_input:
push ra  #to access the array[i] multiply the array index by the size of the item byte (array[2]) == 2*the size byte
	jal input_get_keys_held
	and t0, v0, KEY_L
	beq t0, 0, _endif1
	lw a0, emitter_x
		beq a0, EMITTER_X_MIN, _endif2
		sub a0, a0, 1
		sw a0, emitter_x
		_endif2:	
	_endif1:
	
	and t0, v0, KEY_R
	beq t0, 0, _endif3
	lw a0, emitter_x
		beq a0, EMITTER_X_MAX, _endif4
		add a0, a0, 1
		sw a0, emitter_x
		_endif4:	
	_endif3:
	
	and t0, v0, KEY_U
	beq t0, 0, _endif5
	lw a0, emitter_y
		beq a0, EMITTER_Y_MIN, _endif6
		sub a0, a0, 1
		sw a0, emitter_y
		_endif6:	
	_endif5:
	
	and t0, v0, KEY_D
	beq t0, 0, _endif7
	lw a0, emitter_y
		beq a0, EMITTER_Y_MAX, _endif8
		add a0, a0, 1
		sw a0, emitter_y
		_endif8:	
	_endif7:
	
	and t0, v0, KEY_B
	beq t0, 0, _endif9
	jal spawn_particle
	_endif9:
pop ra	
jr ra

spawn_particle:
push ra
push s0
	jal find_free_particle
	move s0, v0
	beq s0, -1, _end
	#setting particle_active
	li t0, 1
	sb t0, particle_active(s0)
	#mul by the size
	mul s0, s0, 2
	#setting particle_x
	lw t0, emitter_x 
	mul t0, t0, 100
	sh t0, particle_x(s0)
	#setting particle_y
	lw t0, emitter_y
	mul t0, t0, 100
	sh t0, particle_y(s0)
	#setting particle_vx
	li v0, 42
	li a0, 0
	li a1, VEL_RANDOM_MAX
	syscall
	li t1, VEL_RANDOM_MAX_OVER_2
	sub v0, v0, t1
	sh v0, particle_vx(s0)
	#setting particle_vy 
	li v0, 42
	li a0, 0
	li a1, VEL_RANDOM_MAX
	syscall
	li t1, VEL_RANDOM_MAX_OVER_2
	sub v0, v0, t1
	li t2, GRAVITY
	sub v0, v0, t2
	sh v0, particle_vy(s0)
	_end:
	
pop s0
pop ra
jr ra

draw_particles:
push ra
push s0
	li s0, 0
	_loop:
		beq s0, MAX_PARTICLES, _break
		lb t0, particle_active(s0)
		beq t0, 0, _endif
		#mul by the size and store it in another register
		mul s1, s0, 2
		#particle_x
		lhu t1, particle_x(s1)
		div t1, t1, 100
		move a0, t1
		#particle_y
		lhu t2, particle_y(s1)
		div t2, t2, 100
		move a1, t2
		li a2, COLOR_BLUE
		jal display_set_pixel
		_endif:
	add s0, s0, 1
	j _loop
	_break:
pop s0
pop ra
jr ra

update_particles:
push ra
push s0
	li s0, 0
	_loop:
		bge s0, MAX_PARTICLES, _break
		lb t0, particle_active(s0)
		beq t0, 0, _endif
		#mul by the size
		mul s1, s0, 2
		#update particle_vy
		lh t1, particle_vy(s1)
		add t1, t1, GRAVITY
		sh t1, particle_vy(s1)
		#update particle_x
		lh t3, particle_vx(s1)
		lh t4, particle_x(s1)
		add t4, t4, t3
		sh t4, particle_x(s1)
		#update particle_y
		lh t5, particle_vy(s1)
		lh t6, particle_y(s1)
		add t6, t6, t5
		sh t6, particle_y(s1)
		#check for offscreen
		blt t4, PARTICLE_X_MIN, _despawn
		blt t6, PARTICLE_Y_MIN, _despawn
		bgt t4, PARTICLE_X_MAX, _despawn
		bgt t6, PARTICLE_Y_MAX, _despawn
		j _endif
		_despawn:
		li t0, 0
		sb t0, particle_active(s0)
		_endif:
	add s0, s0, 1
	j _loop
	_break:
pop s0
pop ra
jr ra










