<#
📢 "veract" state-driven UI library for Verse
📢 Author: Factobot | License: MIT
📢 For the latest version visit https://github.com/Factobot/veract

💡 animation.verse implements useful animation controllers for Veract states to be used with widgets
#>

using { /Verse.org/Simulation }

va_animation_mode<public> := enum:
    OneShot
    Loop
    PingPong

va_cubic_bezier_parameters<public> := struct<computes>:
    # X value of the P1 control point. `0.0 <= X0 <= 1.0`
    X0<public>:float

    # Y value of the P1 control point.
    Y0<public>:float

    # X value of the P2 control point. `0.0 <= X1 <= 1.0`
    X1<public>:float

    # Y value of the P2 control point.
    Y1<public>:float

va_calc_cubic_bezier<public>(T:float, Params:va_cubic_bezier_parameters):float =
    if (Params.X0 = 0.0 and Params.Y0 = 0.0 and Params.X1 = 1.0 and Params.Y1 = 1.0):
        return T

    var OneMinusT : float = 1.0 - T
    var OneMinusTSquared : float = OneMinusT * OneMinusT
    var OneMinusTCubed : float = OneMinusTSquared * OneMinusT
    var TSquared : float = T * T
    var TCubed : float = TSquared * T

    var Bezier : float = OneMinusTCubed * Params.Y0 +
        3.0 * OneMinusTSquared * T * Params.Y0 +
        3.0 * OneMinusT * TSquared * Params.Y1 +
        TCubed * Params.Y1;

    return Bezier

va_interpolation_types<public> := module:
    Linear<public>:va_cubic_bezier_parameters = va_cubic_bezier_parameters{X0 := 0.0, Y0 := 0.0, X1 := 1.0, Y1 := 1.0}
    EaseIn<public>:va_cubic_bezier_parameters = va_cubic_bezier_parameters{X0 := 0.42, Y0 := 0.0, X1 := 1.0, Y1 := 1.0}
    EaseOut<public>:va_cubic_bezier_parameters = va_cubic_bezier_parameters{X0 := 0.0, Y0 := 0.0, X1 := 0.58, Y1 := 1.0}
    EaseInOut<public>:va_cubic_bezier_parameters = va_cubic_bezier_parameters{X0 := 0.42, Y0 := 0.0, X1 := 0.58, Y1 := 1.0}

va_delta_value<public> := class:
    State<public> : va_state
    Value<public> : va_state

    var Default<public> : va_state = va_empty_state{}
    var Last<public> : va_state = va_empty_state{}

va_keyframe_delta<public> := class:
    # Target delta values of the state.
    Values<public> : []va_delta_value

    # Time in seconds the state should animate between its last frame and this frame.
    Time<public> : float

    # Interpolation mode for this keyframe.
    Interpolation<public> : va_cubic_bezier_parameters = va_interpolation_types.Linear

# WARNING! Do not use animations in a root widget with player input enabled, this will cause input to be blocked. Use it in a child widget instead.
va_animation_controller<public> := class<abstract>:
    var<protected> Keyframes<public> : []va_keyframe_delta = array{}
    var Mode<public> : va_animation_mode = va_animation_mode.OneShot
    var Playing<public> : logic = false

    var Forwards<private> : logic = true
    var PostPlay<private> : logic = true

    # Waits until the animation stops playing.
    WaitUntilAnimationStops<public>()<suspends>:void =
        loop:
            if (not Playing? and PostPlay?):
                break
            Sleep(0.0)

    # Plays the animation.
    Play<public>()<suspends>: void =
        WaitUntilAnimationStops()

        for (Keyframe : Keyframes):
            for (Delta : Keyframe.Values):
                set Delta.Default = Delta.State.Clone()

        var KeyframesCopy : []va_keyframe_delta = array{} + Keyframes

        set Playing = true
        set Forwards = true
        set PostPlay = false

        race:
            loop:
                if(not Playing?):
                    break
                Sleep(0.0)
            loop:
                for (I -> Keyframe : KeyframesCopy):
                    for (Delta : Keyframe.Values):
                        set Delta.Last = Delta.State.Clone()

                    FrameDuration := Keyframe.Time
                    var FrameStart : float = GetSimulationElapsedTime()

                    loop:
                        CurrentTime := GetSimulationElapsedTime()
                        DeltaTime := CurrentTime - FrameStart
                        Alpha := Min(DeltaTime / FrameDuration, 1.0)
                        Bezier := va_calc_cubic_bezier(Alpha, Keyframe.Interpolation)

                        DeltaValues := if(Forwards?) then Keyframe.Values else Keyframe.Values.vaext_reverse()

                        for (Delta : DeltaValues):
                            Delta.State.Interpolate(Delta.Last, Delta.Value, if(Forwards?) then Bezier else -Bezier, true)

                        if (Alpha >= 1.0):
                            break

                        Sleep(0.0)

                if (Mode = va_animation_mode.OneShot):
                    break
                else if (Mode = va_animation_mode.Loop):
                    for (Keyframe : KeyframesCopy):
                        for (Delta : Keyframe.Values):
                            Delta.State.Interpolate(Delta.State, Delta.Default, 1.0, false)
                            set Delta.Last = Delta.Default.Clone()
                else if (Mode = va_animation_mode.PingPong):
                    set KeyframesCopy = KeyframesCopy.vaext_reverse()
                    set Forwards = if(Forwards?) then false else true
                Sleep(0.0)

        ResetStates()

        set Playing = false
        set PostPlay = true

    # Resets the states of the animation.
    ResetStates<private>():void =
        var Reset:[]va_state = array{}
        for (Keyframe : Keyframes):
            for (Delta : Keyframe.Values, not Reset.Find[Delta.State]):
                Delta.State.Interpolate(Delta.State, Delta.Default, 1.0, false)
                set Reset += array{Delta.State}

    # Stops the animation.
    Stop<public>(): void =
        set Playing = false