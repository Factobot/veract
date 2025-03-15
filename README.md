# Veract

Veract is a state-driven UI library for the Verse programming language in Fortnite UEFN. It is inspired by the popular React library and aims to provide a similar *(as possible)* development experience for creating dynamic and interactive UIs in Fortnite.

## Features

- State-driven UI components
- Animation support
- Event handling
- Dependency management

## Installation

To use Veract in your project, include the `veract.verse` file with the "veract" folder in your project directory.

Then, import the library in your script:

```verse
using { veract }
```

 ✅ You're set! You can now start using Veract in your project.

## Usage

### States

States in Veract are used to manage the dynamic data of your UI components. They allow for real-time updates and can be used to create dynamic UIs and animations.

#### Supported State Types

Veract supports various state types, including:

Primitives:
- `va_int_state`: Represents an `int` state.
- `va_float_state`: Represents a `float` state.
- `va_string_state`: Represents a `string` state.
- `va_logic_state`: Represents a `logic` state.

Verse/UE General Types:
- `va_color_state`: Represents a `color` state.
- `va_vector2_state`: Represents a `vector2` state.
- `va_player_state`: Represents a `player` state.
- `va_message_state`: Represents a `message` state. <span style="color:red">*</span>
- `va_texture_state`: Represents a `texture` state. <span style="color:red">*</span>

Widget Types:
- `va_margin_state`: Represents a `margin` state.
- `va_anchor_state`: Represents an `anchors` state.
- `va_image_tiling_state`: Represents an `image_tiling` state.
- `va_text_justification_state`: Represents a `text_justification` state.
- `va_text_overflow_policy_state`: Represents a `text_overflow_policy` state.
- `va_horizontal_alignment_state`: Represents a `horizontal_alignment` state.
- `va_vertical_alignment_state`: Represents a `vertical_alignment` state.
- `va_widget_visibility_state`: Represents a `widget_visibility` state.
- `va_ui_input_mode_state`: Represents a `ui_input_mode` state of a UI.

<span style="color:red">*</span> - These state types represent non-comparable types, hence the base value has to be converted into a `unique` special container before being used. This can be easily done by using the `(Value).ToUnique` extension

Additionally, an array of states can be represented using the `va_array` type. Specific callback types are also supported, this will be discussed in the following sections.

#### Converting Basic Types to States

You can quickly convert basic types to states using the `ToState` extension. For example:

```verse
var IntState : va_int_state = 10.ToState()
var FloatState : va_float_state = 3.14.ToState()
var StringState : va_string_state = "Hello".ToState()
var TextureState : va_texture_state = MyTexture.ToUnique().ToState()
var LogicState : va_logic_state = true.ToLogicState()
var ArrayState : va_array = array{IntState, FloatState, TextureState}.ToArrayState()
```
>⚠️ For non-comparable types, use the `ToUnique` extension first.<br/>⚠️ `logic` types exclusively use the `ToLogicState` extension.

#### Dealing with Verse drawbacks
Using the ToState extension won't be possible in some contexts, for instance in class data-members. In such cases, you can use the `va_empty_state` type to create an empty state and set its value later.

The recommended approach is creating container classes for your states, so they can be managed easily from any class. For example:

```verse
my_state_container := class:
    var MyIntState : va_state = va_empty_state{}

    block:
        set MyIntState = 10.ToState()
```

`va_state` types can be directly assigned to any va_widget property, as they are implicitly converted to the required state type later. You can still easily access the proper state type for updating/reading it as explained [here](#converting-states-to-basic-types).

Another way to declare an state is to explicitly define the state type in your class constructor. For example:

```verse
my_state_container := class:
    var MyIntState : va_int_state = va_int_state{ Value := 10 }
```

#### Using Callbacks as States

You can use callbacks to return any state type with effects. You must specify the state dependencies for the callback to trigger updates. For example:

```verse
...class...
Driving : va_logic_state = va_logic_state{Value:=true}
    # or true.ToLogicState() outside data-member definitions

CanUsePhone<private>()<transacts> : va_state =
    var CanUsePhone : logic = true

    if (Driving.AsLogicState[].Get()):
        set CanUsePhone = false

    CanUsePhone.ToLogicState()

...ui construction...
Widget := va_button_loud:
    Text := "Call".ToState()
    Enabled := CanUsePhone.UseEffect(array{Driving})
```

The UseEffect extension is explained in the [Generators](#generators) section.

#### Converting States to Basic Types

You can convert states back to basic types using the `As<Type>State` extension in case you only have a `va_state` generic reference. For example:

```verse
var IntValue : int = IntState.AsIntState[].Get()
var FloatValue : float = FloatState.AsFloatState[].Get()
var StringValue : string = StringState.AsStringState[].Get()
var LogicValue : logic = LogicState.AsLogicState[].Get()
```

#### Updating States

You can update states by calling the `Set` method on the state object. For example:

```verse
FloatState.Set(1.0) # explicit state update

if (State := IntState.AsIntState[]): # implicit state update
    State.Set(3)
```

Once set, the state will automatically update all the components and dependencies it is linked to.

### Generators

Generators in Veract are used to dynamically generate UI components based on state changes. They are useful for creating dynamic lists and other components that need to update based on state.

#### Using Generators

To use a generator, you need to define a callback state and set it as the generator for a widget. For example:

```verse
DynamicListGenerator<private>()<transacts> : va_state =
    var Slots : []va_stack_box_slot = array{}

    for (Entry : DynamicListEntries.Get(), EntryId := Entry.AsStringState[].Get()):
        set Slots += array:
            va_stack_box_slot:
                HorizontalAlignment := horizontal_alignment.Fill.ToState()
                VerticalAlignment := vertical_alignment.Top.ToState()
                Padding := margin{ Left := 0.0, Top := 10.0 }.ToState()
                Widget := va_stack_box:
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
                                Text := Entry

    va_array:
        Value := Slots + array:
            va_stack_box_slot:
                HorizontalAlignment := horizontal_alignment.Fill.ToState()
                VerticalAlignment := vertical_alignment.Top.ToState()
                Padding := margin{ Left := 0.0, Top := 10.0 }.ToState()
                Widget := va_button_loud:
                    Text := "Add Item +".ToState()
                    OnClick := option{OnAddItemClick}
```

Then, in a compatible va_widget, set the `Generator` property to the callback state, as explained in the section below.

#### UseEffect

The `UseEffect` extension is used to create callbacks with state dependencies. It allows you to specify a list of dependencies, and the callback will be triggered whenever any of the dependencies change.

To use `UseEffect`, you need to define a callback state and set its dependencies. For example:

```verse
DynamicListGenerator<private>()<transacts> : va_state =
    ... (Full code from the previous section) ...

Setup<override>()<suspends> : void =
    set Canvas = va_canvas:
        RootInputMode := ui_input_mode.All.ToState()
        Slots := array:
            va_canvas_slot:
                Anchors := va_anchor.Center.ToAnchor().ToState()
                Alignment := va_anchor.Center.ToAlignment().ToState()
                Offsets := margin{ Left := 0.0, Top := 0.0, Right := 500.0, Bottom := 500.0 }.ToState()
                Widget := va_stack_box:
                    Generator := DynamicListGenerator.UseEffect(array{DynamicListEntries})
                    Orientation := orientation.Vertical

    Canvas.AddToPlayer(Player)
```

>📌 More on generators: If you don't want to use a generator, you can still set the `Slots` property directly with an array of widgets.

### Using Widgets

Veract provides it's own wrapper classes for all the available widgets in Fortnite, prefixed with `va_`. These classes are used to create UI components and manage their properties. States do not support native widget types, so you must use the Veract wrapper classes to create widgets in all instances.

#### Creating Widgets

To create a widget, you can use the Veract wrapper classes. For example:

```verse
MyButton := va_button_loud:
    Text := "Click Me!".ToState()
    OnClick := option{OnButtonClick}
```

All widgets share the same properties as their native counterparts, but with the added benefit of state support. You can set the properties of a widget using states, as shown in the example above. The only difference you may find is that properties with names such as `DefaultText` or `DefaultColor` are replaced with `Text` or `Color` respectively.

If you ever need to access the native widget, you can use the `Native` propety on the Veract widget.

Slot classes such as `canvas_slot` or `stack_box_slot` are also wrapped with `va_` classes. These classes also have the same properties as their native counterparts, but with state support.

Additionally, Veract widgets have a `Key` property that can be used to uniquely identify the widget. This can be useful when dealing with event handlers without having to create custom *"lambda containers"*. The `Key` property is optional and can be omitted if not needed.

#### Rendering Widgets

To render a widget, you need to have a root widget such as a canvas and then add the canvas to a player. For example:

```verse
set Canvas = va_canvas:
    Slots := array:
        va_canvas_slot:
            Offsets := margin{ Left := 0.0, Top := 0.0 }.ToState()
            Widget := va_button_loud:
                Text := "My Button".ToState()
```

Then, you can add the canvas to a player:

```verse
Canvas.AddToPlayer(Player)
```

Currently, root widgets only support up to one player. If you need to render UI for multiple players, you will need to create separate root widgets for each player. This may or may not change in the future.

#### Event Handling

Veract widgets support event handling such as the `OnClick` and `OnValueChanged` properties. You can set the property to a callback state that will be triggered when the widget is interacted with. For example:

```verse
MyButton := va_button_loud:
    Text := "Click Me!".ToState()
    OnClick := option{OnButtonClick}
```

The callback handler should take a `widget_message` argument and a second argument that is the base class of the widget itself. For example:

```verse
OnButtonClick<private>(Message:widget_message, Widget:va_text_button) : void =
    print("Button clicked!")

OnValueChanged<private>(Message:widget_message, Widget:va_slider_regular) : void =
    print("Value changed!")
```

You can use the widget argument to access the properties of the widget that triggered the event such as `Key`.

### Animation Controllers

Veract Animation Controllers are used to create animations for UI components. They allow you to define animations for any state type using keyframe deltas.

#### Creating Animation Controllers

To create an animation controller you can use the `va_animation_controller` abstract class. For example:

```verse
my_anim_animation_controller := class(va_animation_controller):
    StateContainer : my_state_container

    block:
        set Mode = va_animation_mode.PingPong

        set Keyframes = array:
            va_keyframe_delta:
                Values := array:
                    va_delta_value:
                        State := StateContainer.MyScale
                        Value := vector2{Y := 30.0 }.ToState()
                    va_delta_value:
                        State := StateContainer.MyOffset
                        Value := margin{Top := -50.0 }.ToState()

my_ui_class := class:
    StateContainer : my_state_container
    MyAnimController : my_anim_animation_controller

    ...

    Setup() : void =
        set Canvas = va_canvas:
            Slots := array:
                va_canvas_slot:
                    Offsets := StateContainer.MyOffset
                    Widget := va_button_loud:
                        Text := "Animated!".ToState()

        MyAnimController.Play()
```

Here's the breakdown of the animation controller class:

- <span style="color:red">*</span> `Mode`: The animation mode, which can be `va_animation_mode.PingPong`, `va_animation_mode.Loop`, or `va_animation_mode.OneShot`.
- `Keyframes`: An array of keyframe deltas (`va_keyframe_delta`) that define the animation.
    - <span style="color:red">*</span> `Values`: An array of delta values (`va_delta_value`) that define the state changes for each keyframe.
        - <span style="color:red">*</span> `State`: The state to animate.
        - <span style="color:red">*</span> `Value`: The value to animate to as a state of the same type.
        - `Interpolation`: The interpolation method used for the transition between the last keyframe and the current one, which can be `va_interpolation_types.Linear`, `va_interpolation_types.EaseIn`, or `va_interpolation_types.EaseOut`, or `va_interpolation_types.EaseInOut`. You can also create your own interpolation using a `va_cubic_bezier_parameters` struct.

#### Using Animation Controllers

To use an animation controller, you need to call the `Play` method on the controller. This will start the animation based on the keyframes and mode you defined.

When using multiple animation controllers **for the same states**, ensure you stop any other **currently active** controllers with the `Stop` method before starting a new one. Additionally, ensure the active controller is fully stopped by awaiting the `WaitUntilAnimationStops` method. If you don't follow these steps, the animations WILL conflict with each other and cause horrendous lag and bugs.

Please check the examples in the `demo` directory for more practical usage.

#### Animation Controller Best Practices

1. Always manage the lifecycle of your animation controllers to avoid unintended behavior.
2. Use `Stop` before starting new animations on the same states to keep performance optimal.
3. Utilize `WaitUntilAnimationStops` to ensure smooth transitions between animations.
4. Avoid using animations in a root widget with player input enabled, as this can block input. Use animations in child widgets instead.

## Examples

Examples can be found in the `demo` directory.

https://github.com/user-attachments/assets/6bc47df7-60b9-4fc9-a56e-e68c4f12f145

## Contributing

Contributions are welcome! This library is still in development and was made to help the Fortnite UEFN community. If you have any suggestions, bug reports, or feature requests, feel free to open an issue or submit a pull request. Also, it was made by a single person, so there may be some bugs or issues that need to be fixed.

## License

Veract is licensed under the MIT License. See the LICENSE file for more information.

