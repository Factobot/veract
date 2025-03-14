<#
📢 "veract" state-driven UI library for Verse
📢 Author: Factobot | License: MIT
📢 For the latest version visit https://github.com/Factobot/veract
#>

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

using { veract }

square_state_container := class:
    var SquareOffset:va_state = va_empty_state{}
    var SquareScale:va_state = va_empty_state{}

    block:
        set SquareOffset = margin{ Left := 0.0, Top := 150.0 }.ToState()
        set SquareScale = vector2{ X := 100.0, Y := 100.0 }.ToState()

square_outward_spiral_animation_controller := class(va_animation_controller):
    StateContainer : square_state_container

    block:
        set Mode = va_animation_mode.PingPong

        SpiralDuration := 20
        SpiralFrames := SpiralDuration * 30
        FrameTime := 1.0 / 30.0
        RadiusOffset := 1.0
        GrowthFactor := 1.0
        var PreviousOffset : margin = margin{ Left := 0.0, Top := 0.0 }

        for (I := 0 .. SpiralFrames-1):
            T := I * 0.2
            R := RadiusOffset + GrowthFactor * T
            X := R * Cos(T)
            Y := R * Sin(T)

            DX := X - PreviousOffset.Left
            DY := Y - PreviousOffset.Top

            set PreviousOffset = NewOffset := margin{ Left := X, Top := Y }

            set Keyframes += array:
                va_keyframe_delta:
                    Values := array:
                        va_delta_value:
                            State := StateContainer.SquareOffset
                            Value := NewOffset.ToState()
                    Time := FrameTime

square_bounce_animation_controller := class(va_animation_controller):
    StateContainer : square_state_container

    block:
        set Mode = va_animation_mode.Loop

        Duration := 0.5

        set Keyframes = array:
            va_keyframe_delta:
                Values := array:
                    va_delta_value:
                        State := StateContainer.SquareScale
                        Value := vector2{Y := 30.0 }.ToState()
                    va_delta_value:
                        State := StateContainer.SquareOffset
                        Value := margin{Top := -50.0 }.ToState()
                Time := Duration * 0.25
            va_keyframe_delta:
                Values := array:
                    va_delta_value:
                        State := StateContainer.SquareScale
                        Value := vector2{Y := -30.0 }.ToState()
                    va_delta_value:
                        State := StateContainer.SquareOffset
                        Value := margin{Top := -100.0 }.ToState()
                Time := Duration * 0.25
            va_keyframe_delta:
                Values := array:
                    va_delta_value:
                        State := StateContainer.SquareOffset
                        Value := margin{Top := 100.0 }.ToState()
                Time := Duration * 0.25
            va_keyframe_delta:
                Values := array:
                    va_delta_value:
                        State := StateContainer.SquareScale
                        Value := vector2{Y := -70.0 }.ToState()
                    va_delta_value:
                        State := StateContainer.SquareOffset
                        Value := margin{Top := 50.0 }.ToState()
                Time := Duration * 0.25
            va_keyframe_delta:
                Values := array:
                    va_delta_value:
                        State := StateContainer.SquareScale
                        Value := vector2{Y := 70.0 }.ToState()
                Time := Duration * 0.25

demo_ui := class(va_player_ui):
    var SquareStateContainer : square_state_container = square_state_container{}
    var SquareSpiralAnim : ?square_outward_spiral_animation_controller = false
    var SquareBounceAnim : ?square_bounce_animation_controller = false

    var DynamicListEntries : va_array = va_array{}
    var AnimMode : va_string_state = va_string_state{Value:="ModeIdle"}

    block:
        set SquareSpiralAnim = option{square_outward_spiral_animation_controller{StateContainer := SquareStateContainer}}
        set SquareBounceAnim = option{square_bounce_animation_controller{StateContainer := SquareStateContainer}}

    DynamicListGenerator<private>()<transacts> : va_state =
        var Slots : []va_stack_box_slot = array{}

        for (Entry : DynamicListEntries.Get(), EntryId := Entry.AsStringState[].Get()):
            set Slots += array:
                va_stack_box_slot:
                    HorizontalAlignment := horizontal_alignment.Fill.ToState()
                    VerticalAlignment := vertical_alignment.Top.ToState()
                    Padding := margin{ Left := 0.0, Top := 10.0 }.ToState()
                    Widget := va_stack_box:
                        Key := "Entry:{EntryId}"
                        Orientation := orientation.Horizontal
                        Slots := array:
                            va_stack_box_slot:
                                Padding := margin{ Left := 10.0 }.ToState()
                                Widget := va_button_loud:
                                    Key := "Del:{EntryId}"
                                    Text := "-".ToState()
                                    OnClick := option{OnRemoveItemClick}
                            va_stack_box_slot:
                                Widget := va_button_loud:
                                    Key := "Entry:{EntryId}:Text"
                                    Text := Entry

        va_array:
            Value := Slots + array:
                va_stack_box_slot:
                    HorizontalAlignment := horizontal_alignment.Fill.ToState()
                    VerticalAlignment := vertical_alignment.Top.ToState()
                    Padding := margin{ Left := 0.0, Top := 10.0 }.ToState()
                    Widget := va_button_loud:
                        Key := "AddItem"
                        Text := "Add Item +".ToState()
                        OnClick := option{OnAddItemClick}

    OnAddItemClick(Message:widget_message, Button:va_text_button) : void =
        DynamicListEntries.Add("Item #{GetRandomInt(0, 100000)}".ToState())

    OnRemoveItemClick(Message:widget_message, Button:va_text_button) : void =
        for (Entry : DynamicListEntries.Get(), Button.Key = "Del:{Entry.AsStringState[].Get()}", NewArray := DynamicListEntries.Get().RemoveFirstElement[Entry]):
            DynamicListEntries.Set(NewArray)

    ToggleAnimMode(Message:widget_message, Button:va_text_button) : void =
        spawn {ApplyAnimMode(Button.Key)}

    ApplyAnimMode<private>(Mode : string)<suspends> : void =
        AnimMode.Set(Mode)

        if (SSA := SquareSpiralAnim?, SBA := SquareBounceAnim?):
            SSA.Stop()
            SBA.Stop()

            SSA.WaitUntilAnimationStops()
            SBA.WaitUntilAnimationStops()

            case(Mode):
                "ModeSpiral" => spawn {SSA.Play()}
                "ModeBounce" => spawn {SBA.Play()}
                _ => ()

    Setup<override>()<suspends> : void =
        set Canvas = va_canvas:
            Key := "Main"
            RootInputMode := ui_input_mode.All.ToState()
            Slots := array:
                va_canvas_slot:
                    Anchors := va_anchor.Center.ToAnchor().ToState()
                    Alignment := va_anchor.CenterRight.ToAlignment().ToState()
                    Offsets := margin{ Left := 500.0,  Right := 500.0, Bottom := 1080.0 }.ToState()
                    Widget := va_canvas:
                        Key := "DynamicListContainer"
                        Slots := array:
                            va_canvas_slot:
                                Anchors := va_anchor.TopCenter.ToAnchor().ToState()
                                Alignment := va_anchor.TopCenter.ToAlignment().ToState()
                                SizeToContent := true.ToLogicState()
                                Offsets := margin{ Left := 0.0, Top := 100.0 }.ToState()
                                Widget := va_text_block:
                                    Key := "DynamicListTitle"
                                    Text := "Dynamic List".ToState()
                            va_canvas_slot:
                                Anchors := va_anchor.TopCenter.ToAnchor().ToState()
                                Alignment := va_anchor.TopCenter.ToAlignment().ToState()
                                SizeToContent := true.ToLogicState()
                                Offsets := margin{ Left := 0.0, Top := 150.0 }.ToState()
                                Widget := va_stack_box:
                                    Key := "DynamicList"
                                    Generator := DynamicListGenerator.UseEffect(array{DynamicListEntries})
                                    Orientation := orientation.Vertical
                va_canvas_slot:
                    Anchors := va_anchor.Center.ToAnchor().ToState()
                    Alignment := va_anchor.CenterLeft.ToAlignment().ToState()
                    Offsets := margin{ Left := -500.0, Right := 500.0, Bottom := 1080.0 }.ToState()
                    Widget := va_canvas:
                        Key := "DynamicAnimationsContainer"
                        Slots := array:
                            va_canvas_slot:
                                Anchors := va_anchor.TopCenter.ToAnchor().ToState()
                                Alignment := va_anchor.TopCenter.ToAlignment().ToState()
                                SizeToContent := true.ToLogicState()
                                Offsets := margin{ Left := 0.0, Top := 100.0 }.ToState()
                                Widget := va_text_block:
                                    Key := "DynamicAnimationsTitle"
                                    Text := "Dynamic Animations".ToState()
                            va_canvas_slot:
                                Anchors := va_anchor.Center.ToAnchor().ToState()
                                Alignment := va_anchor.Center.ToAlignment().ToState()
                                SizeToContent := true.ToLogicState()
                                Offsets := SquareStateContainer.SquareOffset
                                Widget := va_color_block:
                                    Key := "Square"
                                    Color := NamedColors.Red.ToState()
                                    DesiredSize := SquareStateContainer.SquareScale
                            va_canvas_slot:
                                Anchors := va_anchor.TopCenter.ToAnchor().ToState()
                                Alignment := va_anchor.TopCenter.ToAlignment().ToState()
                                SizeToContent := true.ToLogicState()
                                Offsets := margin{ Top := 150.0 }.ToState()
                                Widget := va_stack_box:
                                    Key := "ModesContainer"
                                    Orientation := orientation.Vertical
                                    Slots := array:
                                        va_stack_box_slot:
                                            Widget := va_button_loud:
                                                Key := "ModeIdle"
                                                Text := "Idle".ToState()
                                                OnClick := option{ToggleAnimMode}
                                        va_stack_box_slot:
                                            Widget := va_button_loud:
                                                Key := "ModeSpiral"
                                                Text := "Spiral".ToState()
                                                OnClick := option{ToggleAnimMode}
                                        va_stack_box_slot:
                                            Widget := va_button_loud:
                                                Key := "ModeBounce"
                                                Text := "Bounce".ToState()
                                                OnClick := option{ToggleAnimMode}

        Canvas.AddToPlayer(Player)

veract_demo := class(creative_device):
    OnBegin<override>()<suspends> : void =
        Sleep(1.0)

        for (Player : GetPlayspace().GetPlayers()):
            demo_ui{Player:=Player}.Setup()
