import Foundation

/// A `Flag` specifies a special attribute of an ``Object``.
/// 
/// Detailed attribute descriptions are taken from
/// [Learning ZIL](https://archive.org/details/Learning_ZIL_Steven_Eric_Meretzky_1995/page/n60/mode/1up)
/// by Steve Meretzky (1995), or
/// [ZIL Course](https://github.com/ZoBoRf/ZILCourse/blob/master/ZILCourse.pdf)
/// by Marc Blank (1982).
public enum Flag: Hashable {
    /// The object's description begins with a vowel.
    ///
    /// "The object's DESC begins with a vowel; any verb default which prints an indefinite article
    /// before the DESC is warned to use 'an' instead of 'a'."
    case beginsWithVowel

    /// The vehicle object should catch dropped items.
    ///
    /// "Found in vehicles, this not-very-important flag means that if the player drops something
    /// while in that vehicle, the object should stay in the vehicle rather than falling to the
    /// floor of the room itself."
    case catchesDroppedItems

    /// The object has been touched, or the room has been visited.
    ///
    /// "
    /// Obviously, no room should be defined with a TOUCHBIT, since at the beginning of the game,
    /// the
    /// object has been taken or otherwise disturbed by the player; for example, once the TOUCHBIT
    /// of an object is set, if it has an FDESC, that FDESC will no longer be used to describe it."
    case hasBeenTouched

    /// The object is an actor.
    case isActor

    /// The object can be attacked.
    case isAttackable

    /// The object is a being worn.
    ///
    /// "This means that a wearable object is currently being worn."
    case isBeingWorn

    /// The object is a body part.
    ///
    /// "The object is a body part: the PIANDS object, for example."
    case isBodyPart

    /// The object can be burned.
    ///
    /// The object is burnable. Generally, most takeable objects which are made out of wood or paper
    /// should have the BURNBIT."
    case isBurnable

    /// The object can be climbed.
    case isClimbable

    /// The object is a container.
    ///
    /// "The object is a container; things can be put inside it, it can be opened and closed, etc."
    case isContainer

    /// The room has been destroyed.
    ///
    /// "One interesting note about ROOMs: they can be destroyed arbitrarily within the context of a
    /// game. This is done by setting the RMUNGBIT of the ROOM and changing the LDESC of the ROOM to
    /// be something appropriate to print whenever the ACTOR attempts to enter the ROOM. The WALK
    /// action checks for the RMUNGBIT and prints the appropriate message."
    case isDestroyed

    /// The object is a device.
    case isDevice

    /// The object is a door.
    ///
    /// "The object is a door and various routines, such as V-OPEN, should treat it as such."
    case isDoor

    /// The object is drinkable.
    case isDrinkable

    /// The object is a rLand.
    ///
    /// "Usually used only for rooms, this bit lets any routine that cares know that the room is dry
    /// land (as most are)."
    case isDryLand

    /// The object is edible.
    case isEdible

    /// The object is female.
    ///
    /// "The object is an ACTOR who is a female. Informs various routines to say 'she' instead of
    /// 'he'."
    case isFemale

    /// The object can be fought.
    case isFightable

    /// The object is flammable.
    ///
    /// "This means that the object is a source of fire. An object with the FLAMEBIT should also
    /// have the ONBIT (since it is providing light) and the LIGHTBIT (since it can be
    /// extinguished)."
    case isFlammable

    /// The object is food.
    case isFood

    /// Tells routines to say "in" instead of "on".
    ///
    /// "Another not-too-important vehicle-related flag, it tells various routines to say 'in the
    /// vehicle' rather than 'on the vehicle.'"
    case isInNotOn

    /// The object is an integral part of another object.
    ///
    /// "This means that the object is an integral part of some other object, and can't be
    /// independently taken or dropped. An example might be a dial or button on a (takeable) piece
    /// of equipment."
    case isIntegral

    /// The object is invisible.
    ///
    /// "One of the few bits that doesn't end in "-BIT," INVISIBLE tells the parser not to find this
    /// object. Usually, the intention is to clear the invisible at some point. For example, you
    /// might clear the invisible bit on the BLOOD-STAIN object after the player examines the
    /// bludgeon. Until that point, referring to the blood stain would get a response like 'You
    /// can't see any blood stain right here.'"
    case isInvisible

    /// The object can be a source of light.
    ///
    /// "The object is capable of being turned on and off, like the old brass lantern from Zork.
    /// However, it doesn't mean that the object is actually on."
    case isLightSource

    /// The object is locked.
    ///
    /// "Tells routines like V-OPEN that an object or door is locked and can't be opened without
    /// proper equipment."
    case isLocked

    /// The object is a maze.
    case isMaze

    /// The room is a mid-air location.
    ///
    /// "The room is in mid-air, for those games with some type of flying."
    case isMidAirLocation

    /// The room is naturally lit and doesn't require a light source.
    ///
    /// This is often used for outdoor rooms during daytime or rooms with ambient light.
    /// In ZIL games, this was typically implemented by setting the ONBIT flag on rooms
    /// that were naturally lit.
    case isNaturallyLit

    /// The object is a not land.
    case isNotLand

    /// The object is turned on.
    ///
    /// In the case of a room, this means that the room is lit. If your game takes place during the
    /// day, any outdoor room should have the ONBIT. In the case of an object, this means that the
    /// object is providing light. An object with the ONBIT should also have the LIGHTBIT."
    case isOn

    /// The object is open.
    ///
    /// "The object is a door or container, and is open."
    case isOpen

    /// The object is openable.
    case isOpenable

    /// The room is an outside location.
    ///
    /// "Used in rooms to classify the room as an outdoors room."
    case isOutside

    /// The object is a person.
    ///
    /// "This means that the object is a character in the game, and such act accordingly. For
    /// example, they can be spoken to. This flag is sometimes called the ACTORBIT."
    case isPerson

    /// The object's description is a plural noun or noun phrase.
    ///
    /// "The object's DESC is a plural noun or noun phrase, such as 'barking dogs,' and routines
    /// which use the DESC should act accordingly."
    case isPlural

    /// The object is readable.
    ///
    /// "The object is readable. Any object with a TEXT property should have the READBIT."
    case isReadable

    /// The object is sacred.
    case isSacred

    /// The object is searchable.
    ///
    /// "A very slippery concept. It tells the parser to look as deeply into a container as it can
    /// in order to find the referenced object. Without the SEARCHBIT, the parser will only look
    /// down two-levels. Example. There's a box on the ground; there's a bowl in the box; there's an
    /// apple in the bowl.
    ///
    /// "If the player says TAKE APPLE, and the box or the bowl have a SEARCHBIT, the apple will be
    /// found by the parser and then taken. If the player says TAKE APPLE, and the box and bowl
    /// don't have the SEARCHBIT, the parser will say "You can't see any apple right here." Frankly,
    /// I think the SEARCHBIT is a stupid concept, and I automatically give the SEARCHBIT to all
    /// containers."
    case isSearchable

    /// The object is staggered.
    case isStaggered

    /// The object is a surface.
    ///
    /// "The object is a surface, such as a table, desk, countertop, etc. Any object with the
    /// SURFACEBIT should also have the CONTBIT (since you can put things on the surface) and the
    /// OPENBIT (since you can't close a countertop as you can a box)."
    case isSurface

    /// The object can be taken.
    case isTakable

    /// The object is a tool.
    case isTool

    /// The object is transparent.
    ///
    /// "The object is transparent; objects inside it can be seen even if it is closed."
    case isTransparent

    /// The object is turnable.
    case isTurnable

    /// The object is a vehicle.
    ///
    /// "This means that the object is a vehicle, and can be entered or boarded by the player. All
    /// objects with the VEHBIT should usually have the CONTBIT and the OPENBIT."
    case isVehicle

    /// The room is a water location.
    ///
    /// "The room is water rather than dry land, such as the River and Reservoir in Zork I. Some
    /// typical implications: The player can't go there without a boat; anyone dropped outside of
    /// the boat will sink and be lost, etc."
    case isWaterLocation

    /// The object is a weapon.
    case isWeapon

    /// The object is wearable.
    ///
    /// "The object can be worn. Given to garments and wearable equipment such as jewelry or a
    /// diving helmet. Only means that the object is wearable, not that it is actually being worn."
    case isWearable

    /// The object should *not* be implicitly taken.
    ///
    /// "This bit tells the parser not to let the player implicitly take an object, as in:
    ///
    /// ```
    /// > READ DECREE
    /// [taking the decree first]
    /// ```
    ///
    /// "This is important if the object has a value and must be scored, or if the object has an
    /// NDESCBIT which must be cleared, or if you want taking the object to set a flag or queue a
    /// routine, or..."
    case noImplicitTake

    /// The object omits an article.
    ///
    /// "The object's DESC doesn't not work with articles, and they should be omitted. An example is
    /// the ME object, which usually has the DESC 'you.' A verb default should say 'It smells just
    /// like you.' rather than 'It smells just like _a_ you.'"
    case omitArticle

    /// The object is a nounDescription.
    ///
    /// "The object shouldn't be described by the describers. This usually means that someone else,
    /// such as the room description, is describing the object. Any takeable object, once taken,
    /// should have its NDESCBIT cleared."
    case omitDescription

    /// The object should be omitted from "take all" operations.
    ///
    /// "This has something to do with telling a TAKE ALL not to take something, but I don't recall
    /// how it works. Help???"
    case omitFromTakeAll

    /// Tells the parser not to complain when the player input is missing a noun.
    ///
    /// [kludge](https://www.lexico.com/en/definition/kludge) _noun_:
    ///
    /// 1. An ill-assorted collection of parts assembled to fulfill a particular purpose.
    /// 2. _Computing_ A machine, system, or program that has been badly put together.
    ///
    /// "This bit is used only in the syntax file. It is used for those syntaxes which want to be
    /// simply VERB PREPOSITION with no object. Put (FIND KLUDGEBIT) after the object. The parser,
    /// rather than complaining about the missing noun, will see the FIND KLUDGEBIT and set the PRSO
    /// (
    /// KLUDGEBIT; this saves a bit, since the parser won't 'find' a room, and no objects have the
    /// RLANDBIT."
    case shouldKludge

    /// A custom flag.
    case custom(String)
}

extension Flag {
    /// Returns a predefined flag matching the original Zil.
    ///
    /// If no matching flag exists, it creates a custom flag based on the Zil string.
    ///
    /// - Parameter zil: A string containing the original Zil flag.
    public init(_ zil: String) {
        switch zil.lowercased() {
        case "vowelbit": self = .beginsWithVowel
        case "dropbit": self = .catchesDroppedItems
        case "touchbit": self = .hasBeenTouched
        case "actorbit": self = .isActor
        case "attackbit": self = .isAttackable
        case "wornbit": self = .isBeingWorn
        case "partbit": self = .isBodyPart
        case "burnbit": self = .isBurnable
        case "climbbit": self = .isClimbable
        case "contbit": self = .isContainer
        case "rmungbit": self = .isDestroyed
        case "devicebit": self = .isDevice
        case "doorbit": self = .isDoor
        case "drinkbit": self = .isDrinkable
        case "rlandbit": self = .isDryLand
        case "ediblebit": self = .isEdible
        case "femalebit": self = .isFemale
        case "fightbit": self = .isFightable
        case "flamebit": self = .isFlammable
        case "foodbit": self = .isFood
        case "inbit": self = .isInNotOn
        case "integralbit": self = .isIntegral
        case "invisible": self = .isInvisible
        case "lightbit": self = .isLightSource
        case "lockedbit": self = .isLocked
        case "mazebit": self = .isMaze
        case "rairbit": self = .isMidAirLocation
        case "nonlandbit": self = .isNotLand
        case "onbit": self = .isOn
        case "openbit": self = .isOpen
        case "openablebit": self = .isOpenable
        case "outsidebit": self = .isOutside
        case "personbit": self = .isPerson
        case "pluralbit": self = .isPlural
        case "readbit": self = .isReadable
        case "sacredbit": self = .isSacred
        case "searchbit": self = .isSearchable
        case "staggered": self = .isStaggered
        case "surfacebit": self = .isSurface
        case "takebit": self = .isTakable
        case "toolbit": self = .isTool
        case "transbit": self = .isTransparent
        case "turnbit": self = .isTurnable
        case "vehbit": self = .isVehicle
        case "rwaterbit": self = .isWaterLocation
        case "weaponbit": self = .isWeapon
        case "wearbit": self = .isWearable
        case "trytakebit": self = .noImplicitTake
        case "narticlebit": self = .omitArticle
        case "ndescbit": self = .omitDescription
        case "nallbit": self = .omitFromTakeAll
        case "kludgebit": self = .shouldKludge
        default: self = .custom(zil)
        }
    }
}

// MARK: - Flag.Quantifier

extension Flag {
    /// A logical quantifier used when matching against flags.
    public enum Quantifier {
        /// Match all flags.
        case all

        /// Match any flag.
        case any
    }
}
