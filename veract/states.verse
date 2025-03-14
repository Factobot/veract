<#
📢 "veract" state-driven UI library for Verse
📢 Author: Factobot | License: MIT
📢 For the latest version visit https://github.com/Factobot/veract

💡 states.verse
      All widget-supported types are represented as states in Veract. This includes all primitive types, as well as more complex types like anchors, margins, and colors.
      Veract States allow for easy real-time updates to widgets, and can be used to create all sorts of dynamic UIs and UI animations.
#>

using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Assets }

va_state<public> := class<abstract><unique>:
    Updated<public>: va_custom_subscribable(tuple()) = va_custom_subscribable(tuple()){}
    Compare<public>(Other : va_state)<transacts><decides> : void
    Interpolate<public>(From:va_state, To:va_state, Alpha:float, Relative:logic) : void =  Err("VERACT: Interpolation not supported for this state type.")
    Getter<public>()<transacts> : va_state = Self
    Clone<public>()<transacts> : va_state

va_immutable_state<public> := class(va_state):
    Compare<override>(Other : va_state)<transacts><decides> : void = false
    Clone<override>()<transacts> : va_state = va_immutable_state{}

va_valueful_state<public>(t : type) := class<abstract>(va_state):
    Get<public>()<transacts> : t
    Set<public>(InValue : t) : void =
        OnSet(InValue)
        Updated.Signal()
    OnSet<public>(InValue : t) : void

va_dependable_valueful_state<public>(t : type) := class<abstract>(va_valueful_state(t)):
    Dependencies<public> : []va_state

    Init<public>() : void =
        for (Dependency : Dependencies):
            if (va_immutable_state[Dependency]):
                Err("VERACT: Dependencies cannot be immutable states.")

            Dependency.Updated.Subscribe(OnDependencyUpdated, va_dummy_widget{})

    OnDependencyUpdated<private>() : void =
        Updated.Signal()

va_dependable_immutable_state<public> := class<abstract>(va_immutable_state):
    var Dependencies<public> : []va_state
    var IsSet<private> : logic = false

    Init<public>() : void =
        for (Dependency : Dependencies, not IsSet?):
            if (va_immutable_state[Dependency]):
                Err("VERACT: Dependencies cannot be immutable states.")

            Dependency.Updated.Subscribe(OnDependencyUpdated, va_dummy_widget{})

        set IsSet = true

    OnDependencyUpdated<private>() : void =
        Updated.Signal()

va_state_callback_type<public> := type{_()<transacts>:va_state}

va_condition_payload<public> := struct:
    Player<public>:?player = false
va_state_condition_callback_type<public> := type{_(p:va_condition_payload)<transacts>:logic}

va_callback_state<public> := class(va_dependable_valueful_state(va_state_callback_type)):
    var<private> Value<public> : va_state_callback_type
    var Dummy<public> : logic = false
    Get<override>()<transacts> : va_state_callback_type = Value
    OnSet<override>(InValue:va_state_callback_type) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value() = va_callback_state[Other].Get()()
    Clone<override>()<transacts> : va_state = va_callback_state{Value := Value, Dependencies := Dependencies}
(Value : va_state_callback_type).UseEffect<public>(Dependencies : []va_state) : va_callback_state =
    Ret:=va_callback_state{Value := Value, Dependencies := Dependencies}
    Ret.Init()
    Ret

(Value : va_valueful_state(t) where t:type).StaticCallbackState<public>() : va_callback_state =
    Ret:=va_callback_state{Value := Value.Getter, Dependencies := array{}}
    Ret.Init()
    Ret
(Value : va_valueful_state(t) where t:type).CallbackState<public>(Dependencies : []va_state) : va_callback_state =
    Ret:=va_callback_state{Value := Value.Getter, Dependencies := Dependencies}
    Ret.Init()
    Ret

va_array<public> := class(va_valueful_state([]va_state)):
    var<private> Value<public> : []va_state = array{}
    Add<public>(InValue : va_state) : void =
        Set(Value + array{InValue})
    Length<public>() : int = Value.Length
    Get<override>()<transacts> : []va_state = Value
    OnSet<override>(InValue:[]va_state) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void =
        var Changed : logic = false
        for (Index -> State : va_array[Other].Get(), not Value[Index].Compare[State]):
            set Changed = true
        Changed?
    Clone<override>()<transacts> : va_state = va_array{Value := Value}
(Value : []va_state).ToArrayState<public>()<transacts> : va_array =
    va_array{Value := Value}
(Value : va_state).AsArrayState<public>()<transacts><decides> : va_array =
    va_array[va_get[Value]]

va_empty_state<public> := class(va_immutable_state):

va_player_state<public> := class(va_valueful_state(player)):
    var<private> Value<public> : player
    Get<override>()<transacts> : player = Value
    OnSet<override>(InValue:player) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_player_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_player_state{Value := Value}
(Value : player).ToState<public>()<transacts> : va_player_state =
    va_player_state{Value := Value}
(Value : va_state).AsPlayerState<public>()<transacts><decides> : va_player_state =
    va_player_state[va_get[Value]]

va_int_state<public> := class(va_valueful_state(int)):
    var<private> Value<public> : int = 0
    Get<override>()<transacts> : int = Value
    OnSet<override>(InValue:int) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_int_state[Other].Get()
    Interpolate<override>(From:va_state, To:va_state, Alpha:float, Relative:logic) : void =
        if(ValueFrom := va_int_state[From].Get(), var ValueTo : int = va_int_state[To].Get()):
            if (Relative?):
                set ValueTo = ValueFrom + ValueTo
            if(NewValue := Round[(ValueFrom * 1.0) + (ValueTo - ValueFrom) * Alpha]):
                Set(NewValue)
    Clone<override>()<transacts> : va_state = va_int_state{Value := Value}
(Value : int).ToState<public>()<transacts> : va_int_state =
    va_int_state{Value := Value}
(Value : va_state).AsIntState<public>()<transacts><decides> : va_int_state =
    va_int_state[va_get[Value]]

va_float_state<public> := class(va_valueful_state(float)):
    var<private> Value<public> : float = 0.0
    Get<override>()<transacts> : float = Value
    OnSet<override>(InValue:float) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_float_state[Other].Get()
    Interpolate<override>(From:va_state, To:va_state, Alpha:float, Relative:logic) : void =
        if(ValueFrom := va_float_state[From].Get(), var ValueTo : float = va_float_state[To].Get()):
            if (Relative?):
                set ValueTo = ValueFrom + ValueTo
            Set(ValueFrom + (ValueTo - ValueFrom) * Alpha)
    Clone<override>()<transacts> : va_state = va_float_state{Value := Value}
(Value : float).ToState<public>()<transacts> : va_float_state =
    va_float_state{Value := Value}
(Value : va_state).AsFloatState<public>()<transacts><decides> : va_float_state =
    va_float_state[va_get[Value]]

va_string_state<public> := class(va_valueful_state(string)):
    var<private> Value<public> : string = ""
    Get<override>()<transacts> : string = Value
    OnSet<override>(InValue:string) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_string_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_string_state{Value := Value}
(Value : string).ToState<public>()<transacts> : va_string_state =
    va_string_state{Value := Value}
(Value : va_state).AsStringState<public>()<transacts><decides> : va_string_state =
    va_string_state[va_get[Value]]

va_unique_message<public> := class<unique>:
    Value<public> : message
va_message_state<public> := class(va_valueful_state(va_unique_message)):
    var<private> Value<public> : va_unique_message
    Get<override>()<transacts> : va_unique_message = Value
    OnSet<override>(InValue:va_unique_message) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_message_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_message_state{Value := Value}
(Value : message).ToState<public>()<transacts> : va_message_state =
    Err("VERACT: You must convert the message to unique with (Value).ToUnique() before using it as a state.")
(Value : message).ToUnique<public>()<transacts> : va_unique_message =
    va_unique_message{Value := Value}
(Value : va_unique_message).ToState<public>()<transacts> : va_message_state =
    va_message_state{Value := Value}
(Value : va_state).AsMessageState<public>()<transacts><decides> : va_message_state =
    va_message_state[va_get[Value]]

va_logic_state<public> := class(va_valueful_state(logic)):
    var<private> Value<public> : logic = false
    Get<override>()<transacts> : logic = Value
    OnSet<override>(InValue:logic) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_logic_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_logic_state{Value := Value}
(Value : logic).ToLogicState<public>()<transacts> : va_logic_state =
    va_logic_state{Value := Value}
(Value : va_state).AsLogicState<public>()<transacts><decides> : va_logic_state =
    va_logic_state[va_get[Value]]

va_widget_visibility_state<public> := class(va_valueful_state(widget_visibility)):
    var<private> Value<public> : widget_visibility = widget_visibility.Visible
    Get<override>()<transacts> : widget_visibility = Value
    OnSet<override>(InValue:widget_visibility) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_widget_visibility_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_widget_visibility_state{Value := Value}
(Value : widget_visibility).ToState<public>()<transacts> : va_widget_visibility_state =
    va_widget_visibility_state{Value := Value}
(Value : va_state).AsWidgetVisibilityState<public>()<transacts><decides> : va_widget_visibility_state =
    va_widget_visibility_state[va_get[Value]]

va_color_state<public> := class(va_valueful_state(color)):
    var<private> Value<public> : color = NamedColors.White
    Get<override>()<transacts> : color = Value
    OnSet<override>(InValue:color) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_color_state[Other].Get()
    Interpolate<override>(From:va_state, To:va_state, Alpha:float, Relative:logic) : void =
        if(ValueFrom := va_color_state[From].Get(), var ValueTo : color = va_color_state[To].Get()):
            if (Relative?):
                set ValueTo = color{R := ValueFrom.R + ValueTo.R, G := ValueFrom.G + ValueTo.G, B := ValueFrom.B + ValueTo.B}
            Set(color{R := (ValueFrom.R * 1.0) + (ValueTo.R - ValueFrom.R) * Alpha, G := (ValueFrom.G * 1.0) + (ValueTo.G - ValueFrom.G) * Alpha, B := (ValueFrom.B * 1.0) + (ValueTo.B - ValueFrom.B) * Alpha})
    Clone<override>()<transacts> : va_state = va_color_state{Value := Value}
(Value : color).ToState<public>()<transacts> : va_color_state =
    va_color_state{Value := Value}
(Value : va_state).AsColorState<public>()<transacts><decides> : va_color_state =
    va_color_state[va_get[Value]]

va_vector2_state<public> := class(va_valueful_state(vector2)):
    var<private> Value<public> : vector2 = vector2{X:=0.0, Y:=0.0}
    Get<override>()<transacts> : vector2 = Value
    OnSet<override>(InValue:vector2) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_vector2_state[Other].Get()
    Interpolate<override>(From:va_state, To:va_state, Alpha:float, Relative:logic) : void =
        if(ValueFrom := va_vector2_state[From].Get(), var ValueTo : vector2 = va_vector2_state[To].Get()):
            if (Relative?):
                set ValueTo = vector2{X := ValueFrom.X + ValueTo.X, Y := ValueFrom.Y + ValueTo.Y}
            Set(vector2{X := ValueFrom.X + (ValueTo.X - ValueFrom.X) * Alpha, Y := ValueFrom.Y + (ValueTo.Y - ValueFrom.Y) * Alpha})
    Clone<override>()<transacts> : va_state = va_vector2_state{Value := Value}
(Value : vector2).ToState<public>()<transacts> : va_vector2_state =
    va_vector2_state{Value := Value}
(Value : va_state).AsVector2State<public>()<transacts><decides> : va_vector2_state =
    va_vector2_state[va_get[Value]]

va_unique_texture<public> := class<unique>:
    Value<public> : texture
va_texture_state<public> := class(va_valueful_state(va_unique_texture)):
    var<private> Value<public> : va_unique_texture
    Get<override>()<transacts> : va_unique_texture = Value
    OnSet<override>(InValue:va_unique_texture) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_texture_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_texture_state{Value := Value}
(Value : texture).ToState<public>()<transacts> : va_texture_state =
    Err("VERACT: You must convert the texture to unique with (Value).ToUnique() before using it as a state.")
(Value : texture).ToUnique<public>()<transacts> : va_unique_texture =
    va_unique_texture{Value := Value}
(Value : va_unique_texture).ToState<public>()<transacts> : va_texture_state =
    va_texture_state{Value := Value}
(Value : va_state).AsTextureState<public>()<transacts><decides> : va_texture_state =
    va_texture_state[va_get[Value]]

va_image_tiling_state<public> := class(va_valueful_state(image_tiling)):
    var<private> Value<public> : image_tiling = image_tiling.Stretch
    Get<override>()<transacts> : image_tiling = Value
    OnSet<override>(InValue:image_tiling) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_image_tiling_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_image_tiling_state{Value := Value}
(Value : image_tiling).ToState<public>()<transacts> : va_image_tiling_state =
    va_image_tiling_state{Value := Value}
(Value : va_state).AsImageTilingState<public>()<transacts><decides> : va_image_tiling_state =
    va_image_tiling_state[va_get[Value]]

va_text_justification_state<public> := class(va_valueful_state(text_justification)):
    var<private> Value<public> : text_justification = text_justification.Left
    Get<override>()<transacts> : text_justification = Value
    OnSet<override>(InValue:text_justification) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_text_justification_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_text_justification_state{Value := Value}
(Value : text_justification).ToState<public>()<transacts> : va_text_justification_state =
    va_text_justification_state{Value := Value}
(Value : va_state).AsTextJustificationState<public>()<transacts><decides> : va_text_justification_state =
    va_text_justification_state[va_get[Value]]

va_text_overflow_policy_state<public> := class(va_valueful_state(text_overflow_policy)):
    var<private> Value<public> : text_overflow_policy = text_overflow_policy.Clip
    Get<override>()<transacts> : text_overflow_policy = Value
    OnSet<override>(InValue:text_overflow_policy) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_text_overflow_policy_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_text_overflow_policy_state{Value := Value}
(Value : text_overflow_policy).ToState<public>()<transacts> : va_text_overflow_policy_state =
    va_text_overflow_policy_state{Value := Value}
(Value : va_state).AsTextOverflowPolicyState<public>()<transacts><decides> : va_text_overflow_policy_state =
    va_text_overflow_policy_state[va_get[Value]]

va_ui_input_mode_state<public> := class(va_valueful_state(ui_input_mode)):
    var<private> Value<public> : ui_input_mode = ui_input_mode.None
    Get<override>()<transacts> : ui_input_mode = Value
    OnSet<override>(InValue:ui_input_mode) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_ui_input_mode_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_ui_input_mode_state{Value := Value}
(Value : ui_input_mode).ToState<public>()<transacts> : va_ui_input_mode_state =
    va_ui_input_mode_state{Value := Value}
(Value : va_state).AsUIInputModeState<public>()<transacts><decides> : va_ui_input_mode_state =
    va_ui_input_mode_state[va_get[Value]]

va_anchor_state<public> := class(va_valueful_state(anchors)):
    var<private> Value<public> : anchors = anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
    Get<override>()<transacts> : anchors = Value
    OnSet<override>(InValue:anchors) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_anchor_state[Other].Get()
    Interpolate<override>(From:va_state, To:va_state, Alpha:float, Relative:logic) : void =
        if(ValueFrom := va_anchor_state[From].Get(), var ValueTo : anchors = va_anchor_state[To].Get()):
            if (Relative?):
                set ValueTo = anchors{
                    Minimum := vector2{X := ValueFrom.Minimum.X + ValueTo.Minimum.X, Y := ValueFrom.Minimum.Y + ValueTo.Minimum.Y},
                    Maximum := vector2{X := ValueFrom.Maximum.X + ValueTo.Maximum.X, Y := ValueFrom.Maximum.Y + ValueTo.Maximum.Y}
                }
            Set(anchors{
                Minimum := vector2{X := ValueFrom.Minimum.X + (ValueTo.Minimum.X - ValueFrom.Minimum.X) * Alpha, Y := ValueFrom.Minimum.Y + (ValueTo.Minimum.Y - ValueFrom.Minimum.Y) * Alpha},
                Maximum := vector2{X := ValueFrom.Maximum.X + (ValueTo.Maximum.X - ValueFrom.Maximum.X) * Alpha, Y := ValueFrom.Maximum.Y + (ValueTo.Maximum.Y - ValueFrom.Maximum.Y) * Alpha}
            })
    Clone<override>()<transacts> : va_state = va_anchor_state{Value := Value}
(Value : anchors).ToState<public>()<transacts> : va_anchor_state =
    va_anchor_state{Value := Value}
(Value : va_state).AsAnchorState<public>()<transacts><decides> : va_anchor_state =
    va_anchor_state[va_get[Value]]

va_margin_state<public> := class(va_valueful_state(margin)):
    var<private> Value<public> : margin = margin{}
    Get<override>()<transacts> : margin = Value
    OnSet<override>(InValue:margin) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_margin_state[Other].Get()
    Interpolate<override>(From:va_state, To:va_state, Alpha:float, Relative:logic) : void =
        if (ValueFrom := va_margin_state[From].Get(), var ValueTo : margin = va_margin_state[To].Get()):
            if (Relative?):
                set ValueTo = margin{
                    Left := ValueFrom.Left + ValueTo.Left,
                    Top := ValueFrom.Top + ValueTo.Top,
                    Right := ValueFrom.Right + ValueTo.Right,
                    Bottom := ValueFrom.Bottom + ValueTo.Bottom
                }
            Set(margin{
                Left := ValueFrom.Left + (ValueTo.Left - ValueFrom.Left) * Alpha,
                Top := ValueFrom.Top + (ValueTo.Top - ValueFrom.Top) * Alpha,
                Right := ValueFrom.Right + (ValueTo.Right - ValueFrom.Right) * Alpha,
                Bottom := ValueFrom.Bottom + (ValueTo.Bottom - ValueFrom.Bottom) * Alpha
            })
    Clone<override>()<transacts> : va_state = va_margin_state{Value := Value}
(Value : margin).ToState<public>()<transacts> : va_margin_state =
    va_margin_state{Value := Value}
(Value : va_state).AsMarginState<public>()<transacts><decides> : va_margin_state =
    va_margin_state[va_get[Value]]

va_horizontal_alignment_state<public> := class(va_valueful_state(horizontal_alignment)):
    var<private> Value<public> : horizontal_alignment = horizontal_alignment.Left
    Get<override>()<transacts> : horizontal_alignment = Value
    OnSet<override>(InValue:horizontal_alignment) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_horizontal_alignment_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_horizontal_alignment_state{Value := Value}
(Value : horizontal_alignment).ToState<public>()<transacts> : va_horizontal_alignment_state =
    va_horizontal_alignment_state{Value := Value}
(Value : va_state).AsHorizontalAlignmentState<public>()<transacts><decides> : va_horizontal_alignment_state =
    va_horizontal_alignment_state[va_get[Value]]

va_vertical_alignment_state<public> := class(va_valueful_state(vertical_alignment)):
    var<private> Value<public> : vertical_alignment = vertical_alignment.Top
    Get<override>()<transacts> : vertical_alignment = Value
    OnSet<override>(InValue:vertical_alignment) : void = set Value = InValue
    Compare<override>(Other : va_state)<transacts><decides> : void = Value = va_vertical_alignment_state[Other].Get()
    Clone<override>()<transacts> : va_state = va_vertical_alignment_state{Value := Value}
(Value : vertical_alignment).ToState<public>()<transacts> : va_vertical_alignment_state =
    va_vertical_alignment_state{Value := Value}
(Value : va_state).AsVerticalAlignmentState<public>()<transacts><decides> : va_vertical_alignment_state =
    va_vertical_alignment_state[va_get[Value]]

<# State utilities #>

# Get the value of a state, extracting the value from a callback if necessary
va_get<public>(State : va_state)<transacts><decides> : va_state =
    var RetState : va_state = State

    if (StateCallback := va_callback_state[State]):
        set RetState = StateCallback.Get()()

    return RetState

# Get the value of a state as a message, converting a string state to a message if necessary
va_get_as_message<public>(State : va_state) : message =
    if(StateRaw := va_get[State]):
        if (StateMessage := va_message_state[StateRaw]):
            return StateMessage.Get().Value
        else if (StateString := va_string_state[StateRaw]):
            return vaext_message(StateString.Get())

    return vaext_message("__va__invalid__")