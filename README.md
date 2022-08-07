# Roblox dynamic reanimation
Roblox reanimation bypass with dynamic velocity

# What is Dynamic velocity?
Dynamic velocity is velocity, which is applied in the direction you, as player moves.
Dynamic velocity uses MoveDirection, which is then used to calculate direction to apply
velocity in.

# Why Dynamic velocity?
When character moves velocity gets applied in direction which player moves in, which in return
minigates most of jittering.

# If you are new to reanimations
Reanimation works as follows: Character gets cloned into local side, motors in real character get removed,
therefore every limb in character can fall. All of these limbs get stabilized to limbs in fake character
and then player's character gets set to fake character.
Velocity gets applied in studs. When you do for example Vector3.new(0,60,0), part moved 60 studs
every physics iteration.
Older, now patched way of doing reanimation didn't need any velocity applied. There are still benefits
of using older method, it is just capped and not as power as it was.

# Motivation
This should be used as learning material. Most if not all reanimations that are public are either:
1. obfuscated
2. old
3. badly coded
There isn't any good way of getting into exploiting. The way I(and alot of exploiters) learned
how to exploit was by reading other peoples code, analyzing what it does. Therefore, this exists.

# Note
This reanimaton was made in a way where it should possibly work in most games, therefore
very specific things like "r15 to r6" won't be added. It is meant to be very versitale.
This reanimation has alot of options(even the option to disable dynamic velocity).
This reanimation doesn't fall under any license, therefore you can use it however you want.
the coding style is snakecase, and if you might send commits, then code it in snakecase.
Much obliged.
