function Start-Game {
    param($Engine)

    $script:Cube = $Engine.Load3DModel("$PSScriptRoot/../assets/cube.obj", 12.0)

    $droneFrames = @(
        @(
            "  _/^\_  ",
            " <[o_o]> ",
            "  /   \  "
        ),
        @(
            "  -/^\_- ",
            " <[O_O]> ",
            "  |   |  "
        )
    )
    $script:Drone = ("Sprite2D" -as [type])::new($droneFrames, 6)
    $script:Drone.X = 20
    $script:Drone.Y = 15
}

function Update-Game {
    param($Engine, $DeltaTime)

    $inputType = "Input" -as [type]

    $script:Cube.Rotation.X += 1.1 * $DeltaTime
    $script:Cube.Rotation.Y += 1.6 * $DeltaTime

    $speed = 45.0
    if ($inputType::IsKeyDown('W')) { $script:Drone.Y -= $speed * $DeltaTime }
    if ($inputType::IsKeyDown('S')) { $script:Drone.Y += $speed * $DeltaTime }
    if ($inputType::IsKeyDown('A')) { $script:Drone.X -= $speed * $DeltaTime }
    if ($inputType::IsKeyDown('D')) { $script:Drone.X += $speed * $DeltaTime }

    if ($inputType::IsKeyDown('1')) { $Engine.Renderer3D.SetRenderMode(1) }
    if ($inputType::IsKeyDown('2')) { $Engine.Renderer3D.SetRenderMode(2) }
    if ($inputType::IsKeyDown('3')) { $Engine.Renderer3D.SetRenderMode(3) }

    $script:Drone.Update($DeltaTime)
    $Engine.Render3D($script:Cube)
    $Engine.Render2D($script:Drone)

    $Engine.DrawText(2, 1, "PWEGAM ENGINE | FPS: $($Engine.CurrentFPS) | WASD: Move 2D Sprite | 1/2/3: 3D Mode | ESC: Quit")
}
