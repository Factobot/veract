<#
📢 "veract" state-driven UI library for Verse
📢 Author: Factobot | License: MIT
📢 For the latest version visit https://github.com/Factobot/veract

💡 widgets.verse contains wrapper classes for all the available widgets in Fortnite with the added benefit of State support.
#>

using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Fortnite.com/UI }

# Canvas slot medium for veract
va_canvas_slot<public> := class(va_dependable_immutable_state):
    # The border for the margin and how the widget is resized with its parent.
    # Values are defined between 0.0 and 1.0.
    Anchors<public>:va_state = va_anchor_state{Value:=anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}}

    # The offset that defined the size and position of the widget.
    # When the anchors are well defined, the Offsets.Left represent the distance in pixels from the Anchors Minimum.X, the Offsets.Bottom represent the distance in pixel from the Anchors Maximum.Y, effectively controlling the desired widget size. When the anchors are not well defined, the Offsets.Left and Offsets.Top represent the widget position and Offsets.Right and Offset.Bottom represent the widget size.
    Offsets<public>:va_state = va_margin_state{Value:=margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}}

    # When true we use the widget's desired size. The size calculated by the Offsets is ignored.
    SizeToContent<public>:va_state = va_logic_state{Value:=false}

    # Alignment is the pivot/origin point of the widget.
    # Starting in the upper left at (0.0,0.0), ending in the lower right at (1.0,1.0).
    Alignment<public>:va_state = va_vector2_state{Value:=vector2{X := 0.0, Y := 0.0}}

    # Z Order of this slot relative to other slots in this canvas panel.
    # Higher values are rendered last (and so they will appear to be on top)
    ZOrder<public>:va_state = va_int_state{Value:=0}

    # The widget assigned to this slot.
    Widget<public>:va_widget

    var Dependencies<override>:[]va_state = array{}

    block:
        set Dependencies = {Anchors, Offsets, SizeToContent, Alignment, ZOrder}

(InSlot : va_canvas_slot).ToNativeSlot()<transacts><decides> : canvas_slot =
    Anchors := InSlot.Anchors.AsAnchorState[].Get()
    Offsets := InSlot.Offsets.AsMarginState[].Get()
    SizeToContent := InSlot.SizeToContent.AsLogicState[].Get()
    Alignment := InSlot.Alignment.AsVector2State[].Get()
    ZOrder := InSlot.ZOrder.AsIntState[].Get()

    canvas_slot:
        Anchors := Anchors
        Offsets := Offsets
        SizeToContent := SizeToContent
        Alignment := Alignment
        ZOrder := va_int32_cast[ZOrder]
        Widget := InSlot.Widget.Native

# Stack box slot medium for veract
va_stack_box_slot<public> := class(va_dependable_immutable_state):
    # The widget assigned to this slot.
    Widget<public>:va_widget

    # Horizontal alignment of the widget inside the slot.
    # This alignment is only applied after the layout space for the widget slot is created and determines the widget alignment within that space.
    HorizontalAlignment<public>:va_state = va_horizontal_alignment_state{Value:=horizontal_alignment.Fill}

    # Vertical alignment of the widget inside the slot.
    # This alignment is only applied after the layout space for the widget slot is created and determines the widget alignment within that space.
    VerticalAlignment<public>:va_state = va_vertical_alignment_state{Value:=vertical_alignment.Fill}

    # Empty distance in pixels that surrounds the widget inside the slot. Assumes 1080p resolution.
    Padding<public>:va_state = va_margin_state{Value:=margin{}}

    # The available space will be distributed proportionally.
    # If not set, the slot will use the desired size of the widget.
    Distribution<public>:va_callback_state = va_callback_state{Value := va_empty_state{}.Getter, Dependencies := array{}}

    var Dependencies<override>:[]va_state = array{}

    block:
        set Dependencies = {HorizontalAlignment, VerticalAlignment, Padding, Distribution}

(InSlot : va_stack_box_slot).ToNativeSlot()<transacts><decides> : stack_box_slot =
    HorizontalAlignment := InSlot.HorizontalAlignment.AsHorizontalAlignmentState[].Get()
    VerticalAlignment := InSlot.VerticalAlignment.AsVerticalAlignmentState[].Get()
    Padding := InSlot.Padding.AsMarginState[].Get()

    var Distribution:?float = false
    if (Val := InSlot.Distribution.AsFloatState[]):
        set Distribution = option{Val.Get()}

    stack_box_slot:
        Widget := InSlot.Widget.Native
        HorizontalAlignment := HorizontalAlignment
        VerticalAlignment := VerticalAlignment
        Padding := Padding
        Distribution := Distribution

# Overlay slot medium for veract
va_overlay_slot<public> := class(va_dependable_immutable_state):
    # The widget assigned to this slot.
    Widget<public>:va_widget

    # Horizontal alignment of the widget inside the slot.
    # This alignment is only applied after the layout space for the widget slot is created and determines the widget alignment within that space.
    HorizontalAlignment<public>:va_state = va_horizontal_alignment_state{Value:=horizontal_alignment.Fill}

    # Vertical alignment of the widget inside the slot.
    # This alignment is only applied after the layout space for the widget slot is created and determines the widget alignment within that space.
    VerticalAlignment<public>:va_state = va_vertical_alignment_state{Value:=vertical_alignment.Fill}

    # Empty distance in pixels that surrounds the widget inside the slot. Assumes 1080p resolution.
    Padding<public>:va_state = va_margin_state{Value:=margin{}}

    var Dependencies<override>:[]va_state = array{}

(InSlot : va_overlay_slot).ToNativeSlot()<transacts><decides> : overlay_slot =
    HorizontalAlignment := InSlot.HorizontalAlignment.AsHorizontalAlignmentState[].Get()
    VerticalAlignment := InSlot.VerticalAlignment.AsVerticalAlignmentState[].Get()
    Padding := InSlot.Padding.AsMarginState[].Get()

    overlay_slot{Widget := InSlot.Widget.Native, HorizontalAlignment := HorizontalAlignment, VerticalAlignment := VerticalAlignment, Padding := Padding}

va_dummy_generator<internal>()<transacts> : va_state = va_immutable_state{}

va_widget<public> := class<abstract>(va_immutable_state):
    # Unique Key identifier for this widget. Generated automatically on construction if not set.
    var<private> Key<public>:string = ""

    # Shows or hides the `widget` without removing itself from the containing `player_ui`.
    Visibility<public>:va_state = va_widget_visibility_state{Value:=widget_visibility.Visible}

    # Enables or disables whether the `player` can interact with this `widget`.
    Enabled<public>:va_state = va_logic_state{Value:=true}

    # If this is a root widget and a player is set, it will be added to the player when the condition is met.
    RootRender<public>:va_state = va_logic_state{Value:=true}

    # if this is a root widget and a player is set, controls input event consumption.
    RootInputMode<public>:va_state = va_ui_input_mode_state{Value:=ui_input_mode.None}

    # if this is a root widget and a player is set, controls the z-order of the widget.
    RootZOrder<public>:va_state = va_int_state{Value:=0}

    var<protected> Native<public> : widget = canvas{}

    var CancelablePool<protected> : []va_custom_cancelable = array{}
    var ExclusiveCancelablePool<protected> : []va_custom_cancelable = array{}
    var RootPlayer<protected> : ?player = false
    var Constructed<public> : logic = false
    var Rendered<protected> : logic = false
    var Children<protected> : []va_widget = array{}
    var Parent<protected> : ?va_widget = false
    var LastGeneratedKey<private> : int = 0

    # Resets the widget by destroying and reconstructing it.
    Reset<public><final>():void=
        Destroy()
        Construct()
        Render()

    # Constructs the widget and initializes its properties.
    Construct<public><final>():void=
        set Constructed = true

        OnWidgetConstruct()

        if (Key = ""):
            set Key = "Widget_{set LastGeneratedKey += 1}"

    # Called when the widget is constructed. Can be overridden by subclasses.
    OnWidgetConstruct<protected>():void

    # Adds an event to the widget's event pool.
    AddEvent<public>(Cancelable:va_custom_cancelable, Exclusive:logic):void=
        if (Exclusive?):
            if (not ExclusiveCancelablePool.Find[Cancelable]):
                set ExclusiveCancelablePool += array{Cancelable}
        else:
            if (not CancelablePool.Find[Cancelable]):
                set CancelablePool += array{Cancelable}

    # Renders the widget and its children.
    Render<public><final>():void=
        set Rendered = true

        OnWidgetRender()

        if (Widget := widget[Native]):
            Visibility.Updated.Subscribe(OnVisibilityUpdated, Self)
            Enabled.Updated.Subscribe(OnEnabledUpdated, Self)

            OnVisibilityUpdated()
            OnEnabledUpdated()

        RootRender.Updated.Subscribe(OnRootRenderUpdated, Self)
        RootInputMode.Updated.Subscribe(OnRootInputModeUpdated, Self)
        RootZOrder.Updated.Subscribe(OnRootZOrderUpdated, Self)

        OnRootRenderUpdated()

    # Called when the widget is rendered. Can be overridden by subclasses.
    OnWidgetRender<protected>():void

    # Destroys the widget and its children.
    Destroy<public><final>():void=
        if (IsRootRender[], Player := RootPlayer?, PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(Native)

        for (Cancelable : ExclusiveCancelablePool):
            Cancelable.Cancel()

        for (Cancelable : CancelablePool):
            Cancelable.Cancel()

        for (Child : Children):
            RemoveChild(Child)

        set CancelablePool = array{}
        set Constructed = false
        set Rendered = false

        OnWidgetDestroy()

    # Called when the widget is destroyed. Can be overridden by subclasses.
    OnWidgetDestroy<protected>():void={}

    # Updates the visibility of the widget.
    OnVisibilityUpdated<private>():void=
        if (Widget := canvas[Native], NewVisibility := Visibility.AsWidgetVisibilityState[]):
            Widget.SetVisibility(NewVisibility.Get())

    # Updates the enabled state of the widget.
    OnEnabledUpdated<private>():void=
        if (Widget := canvas[Native], NewEnabled := Enabled.AsLogicState[]):
            Widget.SetEnabled(NewEnabled.Get())

    # Adds the widget to the player's UI.
    AddToPlayer<public>(Player : player) : void =
        set RootPlayer = option{Player}
        Reset()

    # Removes the widget from the player's UI.
    RemoveFromPlayer<public>() : void =
        if (State := va_logic_state[RootRender]):
            State.Set(false)
        Destroy()

    # Checks if the widget is a root render.
    IsRootRender<public>()<transacts><decides> : void =
        RootRender.AsLogicState[].Get()? and RootPlayer?

    # Updates the root render state of the widget.
    OnRootRenderUpdated<private>() : void =
        if (Raw := va_get[RootRender], Condition := va_logic_state[Raw].Get()):
            if (Condition? and RootPlayer? and not Native.GetRootWidget[]):
                if (Player := RootPlayer?, PlayerUI := GetPlayerUI[Player]):
                    if (not Constructed?):
                        Reset()
                    if (
                        ZOrder := va_int32_cast[RootZOrder.AsIntState[].Get()],
                        InputMode := RootInputMode.AsUIInputModeState[].Get()
                    ):
                        PlayerUI.AddWidget(Native, player_ui_slot{ ZOrder := ZOrder, InputMode := InputMode })

            else if(not Condition? and RootPlayer? and Native.GetRootWidget[]):
                if (Player := RootPlayer?, PlayerUI := GetPlayerUI[Player]):
                    PlayerUI.RemoveWidget(Native)

    # Updates the root input mode of the widget.
    OnRootInputModeUpdated<private>() : void =
        if (State := va_logic_state[RootRender], State.Get()?):
            State.Set(false)
            State.Set(true)

    # Updates the root z-order of the widget.
    OnRootZOrderUpdated<private>() : void =
        if (State := va_logic_state[RootRender], State.Get()?):
            State.Set(false)
            State.Set(true)

    # Adds a child widget.
    AddChild<protected>(Child : va_widget) : void =
        set Children += array{Child}
        set Child.Parent = option{Self}

        if (not Child.Constructed?):
            Child.Reset()

    # Removes a child widget.
    RemoveChild<protected>(Child : va_widget) : void =
        if (NewChildren := Children.RemoveFirstElement[Child]):
            set Children = NewChildren
            set Child.Parent = false
            OnChildRemoved(Child)

    # Called when a child widget is removed. Can be overridden by subclasses.
    OnChildRemoved<protected>(Child : va_widget) : void = {}

va_dummy_widget<public> := class(va_widget):
    OnWidgetConstruct<override>():void={}
    OnWidgetRender<override>():void={}

va_generatable_widget<public> := class<abstract>(va_widget):
    Generator<public>:va_callback_state = va_callback_state{ Dummy := true, Value := va_dummy_generator, Dependencies := array{} }

    OnWidgetConstruct<override><final>() : void =
        OnGeneratableConstruct()

        if (not Generator.Dummy?):
            Generator.Init()
            Generator.Updated.Subscribe(HandleGeneratorUpdated, Self, true)
            HandleGeneratorUpdated()

    OnGeneratableConstruct<protected>() : void

    HandleGeneratorUpdated<private>() : void =
        OnGeneratorUpdated()
        Render()

    OnGeneratorUpdated<protected>() : void

va_canvas_slot_updated_callback<internal> := class:
    Canvas:va_canvas
    Slot:va_canvas_slot

    OnSlotUpdated() : void =
        Canvas.OnSlotUpdated(Slot)

va_canvas<public> := class(va_generatable_widget):
    # The child widgets of the canvas
    var Slots<public>:[]va_canvas_slot = array{}

    OnGeneratableConstruct<override>() : void =
        set Native = canvas{}

    OnGeneratorUpdated<override>() : void =
        for (Cancelable : CancelablePool):
            Cancelable.Cancel()
        set CancelablePool = array{}

        for (Child : Children):
            RemoveChild(Child)

        set Slots = array{}

        if (Array := va_array[Generator.Get()()]):
            for (Slot : Array.Get()):
                if (State := va_canvas_slot[Slot]):
                    set Slots += array{State}
                else:
                    Err("VERACT: Invalid element provided to canvas generator. Expected va_canvas_slot.")

    OnSlotUpdated<public>(Slot : va_canvas_slot) : void =
        for (Child : Children, Child = Slot.Widget):
            RemoveChild(Child)

        AddChild(Slot.Widget)

        if (Widget := canvas[Native], SlotNative := Slot.ToNativeSlot[]):
            Widget.AddWidget(SlotNative)

    OnWidgetRender<override>():void =
        if (Widget := canvas[Native]):
            for (Slot : Slots):
                AddChild(Slot.Widget)

                if (SlotNative := Slot.ToNativeSlot[]):
                    for (Dependency : Slot.Dependencies):
                        Dependency.Updated.Subscribe(va_canvas_slot_updated_callback{Canvas:=Self,Slot:=Slot}.OnSlotUpdated, Self)

                    Widget.AddWidget(SlotNative)

    OnChildRemoved<override>(Child : va_widget):void =
        if (Widget := canvas[Native]):
            Widget.RemoveWidget(Child.Native)

va_stack_box_slot_updated_callback<internal> := class:
    Canvas:va_stack_box
    Slot:va_stack_box_slot

    OnSlotUpdated() : void =
        Canvas.OnSlotUpdated(Slot)

va_stack_box<public> := class(va_generatable_widget):
    # The child widgets of the stack box
    var Slots<public>:[]va_stack_box_slot = array{}

    # The orientation of the stack box. Either stack widgets horizontal or vertical.
    Orientation<public>:orientation = orientation.Horizontal

    OnGeneratableConstruct<override>() : void =
        set Native = stack_box{Orientation:=Orientation}

    OnGeneratorUpdated<override>() : void =
        for (Cancelable : CancelablePool):
            Cancelable.Cancel()
        set CancelablePool = array{}

        for (Child : Children):
            RemoveChild(Child)

        set Slots = array{}

        if (Array := va_array[Generator.Get()()]):
            for (Slot : Array.Get()):
                if (State := va_stack_box_slot[Slot]):
                    set Slots += array{State}
                else:
                    Err("VERACT: Invalid element provided to stack box generator. Expected va_stack_box_slot.")

    OnSlotUpdated<public>(Slot : va_stack_box_slot) : void =
        for (Child : Children, Child = Slot.Widget):
            RemoveChild(Child)

        AddChild(Slot.Widget)

        if (Widget := stack_box[Native], SlotNative := Slot.ToNativeSlot[]):
            Widget.AddWidget(SlotNative)

    OnWidgetRender<override>():void =
        if (Widget := stack_box[Native]):
            for (Slot : Slots):
                AddChild(Slot.Widget)

                if (SlotNative := Slot.ToNativeSlot[]):
                    for (Dependency : Slot.Dependencies):
                        Dependency.Updated.Subscribe(va_stack_box_slot_updated_callback{Canvas:=Self,Slot:=Slot}.OnSlotUpdated, Self)

                    Widget.AddWidget(SlotNative)

    OnChildRemoved<override>(Child : va_widget):void =
        if (Widget := stack_box[Native]):
            Widget.RemoveWidget(Child.Native)

va_overlay_slot_updated_callback<internal> := class:
    Canvas:va_overlay
    Slot:va_overlay_slot

    OnSlotUpdated() : void =
        Canvas.OnSlotUpdated(Slot)

va_overlay<public> := class(va_generatable_widget):
    # The child widgets of the overlay
    var Slots<public>:[]va_overlay_slot = array{}

    OnGeneratableConstruct<override>() : void =
        set Native = overlay{}

    OnGeneratorUpdated<override>() : void =
        for (Cancelable : CancelablePool):
            Cancelable.Cancel()
        set CancelablePool = array{}

        for (Child : Children):
            RemoveChild(Child)

        set Slots = array{}

        if (Array := va_array[Generator.Get()()]):
            for (Slot : Array.Get()):
                if (State := va_overlay_slot[Slot]):
                    set Slots += array{State}
                else:
                    Err("VERACT: Invalid element provided to overlay generator. Expected va_overlay_slot.")

    OnSlotUpdated<public>(Slot : va_overlay_slot) : void =
        for (Child : Children, Child = Slot.Widget):
            RemoveChild(Child)

        AddChild(Slot.Widget)

        if (Widget := overlay[Native], SlotNative := Slot.ToNativeSlot[]):
            Widget.AddWidget(SlotNative)

    OnWidgetRender<override>():void =
        if (Widget := overlay[Native]):
            for (Slot : Slots):
                AddChild(Slot.Widget)

                if (SlotNative := Slot.ToNativeSlot[]):
                    for (Dependency : Slot.Dependencies):
                        Dependency.Updated.Subscribe(va_overlay_slot_updated_callback{Canvas:=Self,Slot:=Slot}.OnSlotUpdated, Self)

                    Widget.AddWidget(SlotNative)

    OnChildRemoved<override>(Child : va_widget):void =
        if (Widget := overlay[Native]):
            Widget.RemoveWidget(Child.Native)

va_button_callback_type<public> := type{_(:widget_message,:va_text_button):void}

va_text_button<public> := class<abstract>(va_widget):
    # The text to display to the user.
    var<private> Text<public> : va_state

    # Callback that fires when the button is clicked.
    var<private> OnClick<public> : ?va_button_callback_type = false

    OnWidgetRender<override>():void =
        if (Widget := text_button_base[Native]):
            Widget.OnClick().Subscribe(OnClickInternal)
            Text.Updated.Subscribe(OnTextUpdated, Self)
            OnTextUpdated()

    OnTextUpdated<private>() : void =
        if (Widget := text_button_base[Native]):
            Widget.SetText(va_get_as_message(Text))

    OnClickInternal<private>(Message : widget_message) : void =
        if (Handler := OnClick?):
            Handler(Message, Self)

va_button_loud<public> := class(va_text_button):
    OnWidgetConstruct<override>() : void =
        set Native = button_loud{}

va_button_regular<public> := class(va_text_button):
    OnWidgetConstruct<override>() : void =
        set Native = button_regular{}

va_button_quiet<public> := class(va_text_button):
    OnWidgetConstruct<override>() : void =
        set Native = button_quiet{}

va_text_base<public> := class<abstract>(va_widget):
    # The text to display to the user.
    var<private> Text<public>:va_state

    # The color of the displayed text.
    var<private> TextColor<public>:va_state = va_color_state{Value:=NamedColors.White}

    # The opacity of the displayed text.
    var<private> TextOpacity<public>:va_state = va_float_state{Value:=1.0}

    # The justification to display to the user.
    var<private> Justification<public>:va_state = va_text_justification_state{Value:=text_justification.Left}

    # The policy that determine what happens when the text is longer than its allowed length.
    var<private> OverflowPolicy<public>:va_state = va_text_overflow_policy_state{Value:=text_overflow_policy.Clip}

    OnWidgetRender<override>():void =
        if (Widget := text_base[Native]):
            Text.Updated.Subscribe(OnTextUpdated, Self)
            TextColor.Updated.Subscribe(OnTextColorUpdated, Self)
            TextOpacity.Updated.Subscribe(OnTextOpacityUpdated, Self)
            Justification.Updated.Subscribe(OnJustificationUpdated, Self)
            OverflowPolicy.Updated.Subscribe(OnOverflowPolicyUpdated, Self)

            OnTextUpdated()
            OnTextColorUpdated()
            OnTextOpacityUpdated()
            OnJustificationUpdated()
            OnOverflowPolicyUpdated()

    OnTextUpdated<private>() : void =
        if (Widget := text_base[Native]):
            Widget.SetText(va_get_as_message(Text))

    OnTextColorUpdated<private>() : void =
        if (Widget := text_base[Native], NewColor := TextColor.AsColorState[]):
            Widget.SetTextColor(NewColor.Get())

    OnTextOpacityUpdated<private>() : void =
        if (Widget := text_base[Native], NewOpacity := TextOpacity.AsFloatState[], Conformed := va_float_normal_cast[NewOpacity.Get()]):
            Widget.SetTextOpacity(Conformed)

    OnJustificationUpdated<private>() : void =
        if (Widget := text_base[Native], NewJustification := Justification.AsTextJustificationState[]):
            Widget.SetJustification(NewJustification.Get())

    OnOverflowPolicyUpdated<private>() : void =
        if (Widget := text_base[Native], NewOverflowPolicy := OverflowPolicy.AsTextOverflowPolicyState[]):
            Widget.SetOverflowPolicy(NewOverflowPolicy.Get())

va_text_block<public> := class(va_text_base):
    # The direction the shadow is cast.
    ShadowOffset<public>:va_state = va_vector2_state{Value:=vector2{X:=0.0, Y:=0.0}}

    # The color of the shadow.
    ShadowColor<public>:va_state = va_color_state{Value:=NamedColors.Black}

    # The opacity of the shadow.
    ShadowOpacity<public>:va_state = va_float_state{Value:=0.0}

    OnWidgetConstruct<override>() : void =
        set Native = text_block{}

    OnWidgetRender<override>():void =
        (super:)OnWidgetRender()

        if (Widget := text_block[Native]):
            ShadowOffset.Updated.Subscribe(OnShadowOffsetUpdated, Self)
            ShadowColor.Updated.Subscribe(OnShadowColorUpdated, Self)
            ShadowOpacity.Updated.Subscribe(OnShadowOpacityUpdated, Self)

            OnShadowOffsetUpdated()
            OnShadowColorUpdated()
            OnShadowOpacityUpdated()

    OnShadowOffsetUpdated<private>() : void =
        if (Widget := text_block[Native], NewOffset := ShadowOffset.AsVector2State[]):
            Widget.SetShadowOffset(option{NewOffset.Get()})

    OnShadowColorUpdated<private>() : void =
        if (Widget := text_block[Native], NewColor := ShadowColor.AsColorState[]):
            Widget.SetShadowColor(NewColor.Get())

    OnShadowOpacityUpdated<private>() : void =
        if (Widget := text_block[Native], NewOpacity := ShadowOpacity.AsFloatState[], Conformed := va_float_normal_cast[NewOpacity.Get()]):
            Widget.SetShadowOpacity(Conformed)

va_slider_changed_callback_type<public> := type{_(:widget_message, :va_slider_regular):void}

va_slider_regular<public> := class(va_widget):
    # The value to display to the user.
    Value<public>:va_state = va_float_state{Value:=0.0}

    # The minimum value that the slider can have.
    MinValue<public>:va_state = va_float_state{Value:=0.0}

    # The maximum value that the slider can have.
    MaxValue<public>:va_state = va_float_state{Value:=100.0}

    # The amount to adjust the value by, when using a controller or keyboard.
    StepSize<public>:va_state = va_float_state{Value:=1.0}

    # Callback that fires when the value of the slider has changed.
    var<private> OnValueChanged<public> : ?va_slider_changed_callback_type = false

    OnWidgetConstruct<override>() : void =
        set Native = slider_regular{}

    OnWidgetRender<override>():void =
        if (Widget := slider_regular[Native]):
            Value.Updated.Subscribe(OnValueUpdated, Self)
            MinValue.Updated.Subscribe(OnMinValueUpdated, Self)
            MaxValue.Updated.Subscribe(OnMaxValueUpdated, Self)
            StepSize.Updated.Subscribe(OnStepSizeUpdated, Self)
            Widget.OnValueChanged().Subscribe(OnValueChangedInternal)

            OnValueUpdated()
            OnMinValueUpdated()
            OnMaxValueUpdated()
            OnStepSizeUpdated()

    OnValueChangedInternal<private>(Message : widget_message) : void =
        if (Handler := OnValueChanged?):
            Handler(Message, Self)

    OnValueUpdated<private>() : void =
        if (Widget := slider_regular[Native], NewValue := Value.AsFloatState[]):
            Widget.SetValue(NewValue.Get())

    OnMinValueUpdated<private>() : void =
        if (Widget := slider_regular[Native], NewMinValue := MinValue.AsFloatState[]):
            Widget.SetMinValue(NewMinValue.Get())

    OnMaxValueUpdated<private>() : void =
        if (Widget := slider_regular[Native], NewMaxValue := MaxValue.AsFloatState[]):
            Widget.SetMaxValue(NewMaxValue.Get())

    OnStepSizeUpdated<private>() : void =
        if (Widget := slider_regular[Native], NewStepSize := StepSize.AsFloatState[]):
            Widget.SetStepSize(NewStepSize.Get())

va_color_block<public> := class(va_widget):
    # The color of the widget.
    Color<public>:va_state = va_color_state{Value:=NamedColors.White}

    # The opacity of the widget.
    Opacity<public>:va_state = va_float_state{Value:=1.0}

    # The size this widget desired to be displayed in.
    DesiredSize<public>:va_state = va_vector2_state{Value:=vector2{X:=100.0, Y:=40.0}}

    OnWidgetConstruct<override>() : void =
        set Native = color_block{}

    OnWidgetRender<override>():void =
        if (Widget := color_block[Native]):
            Color.Updated.Subscribe(OnColorUpdated, Self)
            Opacity.Updated.Subscribe(OnOpacityUpdated, Self)
            DesiredSize.Updated.Subscribe(OnDesiredSizeUpdated, Self)

            OnColorUpdated()
            OnOpacityUpdated()
            OnDesiredSizeUpdated()

    OnColorUpdated<private>() : void =
        if (Widget := color_block[Native], NewColor := Color.AsColorState[]):
            Widget.SetColor(NewColor.Get())

    OnOpacityUpdated<private>() : void =
        if (Widget := color_block[Native], NewOpacity := Opacity.AsFloatState[], Conformed := va_float_normal_cast[NewOpacity.Get()]):
            Widget.SetOpacity(Conformed)

    OnDesiredSizeUpdated<private>() : void =
        if (Widget := color_block[Native], NewDesiredSize := DesiredSize.AsVector2State[]):
            Widget.SetDesiredSize(NewDesiredSize.Get())

va_texture_block<public> := class(va_widget):
    # The image to render.
    Image<public>:va_state

    # Tinting applied to the image.
    Tint<public>:va_state = va_color_state{Value:=NamedColors.White}

    # The size this widget desired to be displayed in.
    DesiredSize<public>:va_state = va_vector2_state{Value:=vector2{X:=100.0, Y:=40.0}}

    # The horizontal tiling option.
    HorizontalTiling<public>:va_state = va_image_tiling_state{Value:=image_tiling.Stretch}

    # The vertical tiling option.
    VerticalTiling<public>:va_state = va_image_tiling_state{Value:=image_tiling.Stretch}

    OnWidgetConstruct<override>() : void =
        if (DefaultImage := Image.AsTextureState[]):
            set Native = texture_block{ DefaultImage := DefaultImage.Get().Value }

    OnWidgetRender<override>():void =
        if (Widget := texture_block[Native]):
            Image.Updated.Subscribe(OnImageUpdated, Self)
            Tint.Updated.Subscribe(OnTintUpdated, Self)
            DesiredSize.Updated.Subscribe(OnDesiredSizeUpdated, Self)
            HorizontalTiling.Updated.Subscribe(OnTilingUpdated, Self)
            VerticalTiling.Updated.Subscribe(OnTilingUpdated, Self)

            OnImageUpdated()
            OnTintUpdated()
            OnDesiredSizeUpdated()
            OnTilingUpdated()

    OnImageUpdated<private>() : void =
        if (Widget := texture_block[Native], NewImage := Image.AsTextureState[]):
            Widget.SetImage(NewImage.Get().Value)

    OnTintUpdated<private>() : void =
        if (Widget := texture_block[Native], NewTint := Tint.AsColorState[]):
            Widget.SetTint(NewTint.Get())

    OnDesiredSizeUpdated<private>() : void =
        if (Widget := texture_block[Native], NewDesiredSize := DesiredSize.AsVector2State[]):
            Widget.SetDesiredSize(NewDesiredSize.Get())

    OnTilingUpdated<private>() : void =
        if (Widget := texture_block[Native], NewHorizontalTiling := HorizontalTiling.AsImageTilingState[], NewVerticalTiling := VerticalTiling.AsImageTilingState[]):
            Widget.SetTiling(NewHorizontalTiling.Get(), NewVerticalTiling.Get())

<# Experimental #>

va_custom_button<constructor><public>(Image:va_state, Size:vector2, ?OnClick:?va_button_callback_type = false)<transacts> := va_canvas:
    Slots := array:
        va_canvas_slot:
            Anchors := va_anchor.Center.ToAnchor().ToState()
            Alignment := va_anchor.Center.ToAlignment().ToState()
            SizeToContent := false.ToLogicState()
            Offsets := margin{Left := 0.0, Top := 0.0, Right := Size.X , Bottom:= Size.Y }.ToState()
            Widget := va_texture_block:
                Image := Image
        va_canvas_slot:
            Anchors := va_anchor.Center.ToAnchor().ToState()
            Alignment := va_anchor.Center.ToAlignment().ToState()
            Offsets := margin{Left := 0.0, Top := 0.0, Right := Size.X , Bottom:= Size.Y }.ToState()
            SizeToContent := false.ToLogicState()
            ZOrder := 1.ToState()
            Widget := va_button_quiet:
                Text := "".ToState()
                OnClick := OnClick
