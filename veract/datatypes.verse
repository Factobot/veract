<#
📢 "veract" state-driven UI library for Verse
📢 Author: Factobot | License: MIT
📢 For the latest version visit https://github.com/Factobot/veract

💡 datatypes.verse contains useful data types that are used throughout the library.
#>

using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }

va_anchor<public> := enum:
    Stretch,
    TopLeft,
    TopCenter,
    TopRight,
    CenterLeft,
    Center,
    CenterRight,
    BottomLeft,
    BottomCenter,
    BottomRight

(A : va_anchor).ToAnchor<public>()<transacts> : anchors =
    case (A):
        va_anchor.Stretch => anchors{ Minimum := vector2{ X := 0.0, Y := 0.0 }, Maximum := vector2{ X := 1.0, Y := 1.0 } }
        va_anchor.TopLeft => anchors{ Minimum := vector2{ X := 0.0, Y := 0.0 }, Maximum := vector2{ X := 0.0, Y := 0.0 } }
        va_anchor.TopCenter => anchors{ Minimum := vector2{ X := 0.5, Y := 0.0 }, Maximum := vector2{ X := 0.5, Y := 0.0 } }
        va_anchor.TopRight => anchors{ Minimum := vector2{ X := 1.0, Y := 0.0 }, Maximum := vector2{ X := 1.0, Y := 0.0 } }
        va_anchor.CenterLeft => anchors{ Minimum := vector2{ X := 0.0, Y := 0.5 }, Maximum := vector2{ X := 0.0, Y := 0.5 } }
        va_anchor.Center => anchors{ Minimum := vector2{ X := 0.5, Y := 0.5 }, Maximum := vector2{ X := 0.5, Y := 0.5 } }
        va_anchor.CenterRight => anchors{ Minimum := vector2{ X := 1.0, Y := 0.5 }, Maximum := vector2{ X := 1.0, Y := 0.5 } }
        va_anchor.BottomLeft => anchors{ Minimum := vector2{ X := 0.0, Y := 1.0 }, Maximum := vector2{ X := 0.0, Y := 1.0 } }
        va_anchor.BottomCenter => anchors{ Minimum := vector2{ X := 0.5, Y := 1.0 }, Maximum := vector2{ X := 0.5, Y := 1.0 } }
        va_anchor.BottomRight => anchors{ Minimum := vector2{ X := 1.0, Y := 1.0 }, Maximum := vector2{ X := 1.0, Y := 1.0 } }

(A : va_anchor).ToAlignment<public>()<transacts> : vector2 =
    case (A):
        va_anchor.Stretch => vector2{ X := 0.0, Y := 0.0 }
        va_anchor.TopLeft => vector2{ X := 0.0, Y := 0.0 }
        va_anchor.TopCenter => vector2{ X := 0.5, Y := 0.0 }
        va_anchor.TopRight => vector2{ X := 1.0, Y := 0.0 }
        va_anchor.CenterLeft => vector2{ X := 0.0, Y := 0.5 }
        va_anchor.Center => vector2{ X := 0.5, Y := 0.5 }
        va_anchor.CenterRight => vector2{ X := 1.0, Y := 0.5 }
        va_anchor.BottomLeft => vector2{ X := 0.0, Y := 1.0 }
        va_anchor.BottomCenter => vector2{ X := 0.5, Y := 1.0 }
        va_anchor.BottomRight => vector2{ X := 1.0, Y := 1.0 }