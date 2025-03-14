<#
📢 "veract" state-driven UI library for Verse
📢 Author: Factobot | License: MIT
📢 For the latest version visit https://github.com/Factobot/veract

💡 extensions.verse contains useful functions and types that are used throughout the library.
#>

using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }

vaext_message<public><localizes>(Text : string)<transacts> : message = "{Text}"

(Input:[]t where t:type).vaext_reverse<public>()<computes>:[]t =
    LastIndex := Input.Length - 1
    for (
        CurrentIndex->Unused : Input
        Element := Input[LastIndex - CurrentIndex]
    ). Element

(Map:[keytype]valuetype where keytype:subtype(comparable), valuetype:type).vaext_remove_key<public>(ElementToRemove:keytype):[keytype]valuetype=
    var NewMap:[keytype]valuetype = map{}
    for (Key -> Value : Map, Key <> ElementToRemove):
        set NewMap = ConcatenateMaps(NewMap, map{Key => Value})
    return NewMap

va_custom_cancelable<public> := class<unique>:
    var Canceled : logic = false
    CancelEvent : event() = event(){}
    Cancel():void=
        set Canceled = true
        CancelEvent.Signal()

va_custom_subscribable<public>(t:type)<computes> := class(awaitable(t)):
    InnerEvent : event(t) = event(t){}
    Subscribe(Callback:type {__(:t):void},Widget:va_widget):va_custom_cancelable=
        Subscribe(Callback, Widget, false)
    Subscribe(Callback:type {__(:t):void},Widget:va_widget,Exclusive:logic):va_custom_cancelable=
        Cancelable := va_custom_cancelable{}
        spawn{_WaitForEvent(Callback, Cancelable)}
        Widget.AddEvent(Cancelable, Exclusive)
        Cancelable
    _WaitForEvent(Callback:type {__(:t):void}, Cancelable: va_custom_cancelable)<suspends>:void=
        race:
            loop:
                Payload := InnerEvent.Await()
                if(not Cancelable.Canceled?):
                    Callback(Payload)
                else:
                    break
            Cancelable.CancelEvent.Await()
    Signal<public>(Payload:t):void =
        InnerEvent.Signal(Payload)
    Await<override>()<suspends>:t=
        InnerEvent.Await()

va_int32_cast := (type {_X:int where 0 <= _X, _X <= 2147483647})
va_float_normal_cast := (type {_X:float where 0.0 <= _X, _X <= 1.0})

# Used as a generic UI container/builder for the player.
va_player_ui<public> := class<abstract>:
    Player<public>:player
    var Canvas<public>:va_canvas = va_canvas{}

    # Sets up the player UI.
    Setup<public>()<suspends>:void
    # Removes the player UI.
    Remove<public>():void=Canvas.RemoveFromPlayer()