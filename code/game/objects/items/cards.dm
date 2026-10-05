#define MAX_HAND_SIZE 10

/datum/playingcard
	var/name = "playing card"
	var/front_icon_state = "hand1"
	var/back_icon_state = "singlecard_down"
	/// If this is TRUE, the card will be rendered upside-down.
	var/reversed = FALSE
	var/icon = 'icons/roguetown/items/cards/playingcards.dmi'

// Card intents

/datum/intent/hand/deal
	name = "deal"
	icon_state = "indeal"

/datum/intent/hand/deal/faceup
	name = "deal (face-up)"
	icon_state = "indeal-faceup"

/datum/intent/hand/deal/facedown
	name = "deal (face-down)"
	icon_state = "indeal-facedown"

// Hand of cards. Holds one or more cards

/obj/item/card_hand
	name = "hand of cards"
	icon = 'icons/roguetown/items/cards/playingcards.dmi'
	icon_state = "hand1"
	dropshrink = 0.5
	var/list/cards = list()
	/// The original deck we come from. Our cards can ONLY be taken from / put into this deck, and no other.
	var/obj/item/deck/our_deck = null
	var/concealed = TRUE

/obj/item/card_hand/attack_self(mob/user)
	. = ..()
	concealed = !concealed
	update_icon()
	user.visible_message(span_notice("\The [user] [concealed ? "conceals" : "reveals"] [user.p_their()] hand."), span_notice("I [concealed ? "conceal" : "reveal"] my hand."), span_notice("I hear the flipping of card stock."))

/obj/item/card_hand/examine(mob/user)
	. = ..()
	if((!concealed) && cards.len)
		. += "<details><summary>[span_notice("Cards in Hand")]</summary>"
		for(var/datum/playingcard/C in cards)
			. += span_smallnotice("[icon2html(C.icon, user, C.front_icon_state)] [C.name]")
		. += "</details>"

// Card decks

// Generic card deck. Do not directly spawn this ingame - use one of the subtyes!!
/obj/item/deck
	name = "deck of impossible and broken cards"
	desc = "You should not be seeing this. If you see this, report it to a developer!!"
	icon = 'icons/roguetown/items/cards/playingcards.dmi'
	icon_state = "deck_full"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0
	var/list/cards = list()
	/// Number of times we will duplicate our deck's contents when created. 2 makes a double sized deck, 3 makes triple sized, etc.
	var/deck_size = 1
	/// How many cards are dealt at a time when our holder deals a hand
	var/hand_size = 5
	grid_width = 32
	grid_height = 32
	possible_item_intents = list(/datum/intent/hand/deal/facedown, /datum/intent/hand/deal/faceup)

/// Returns whether or not the given user is able to access cheating mechanics.
/obj/item/deck/proc/can_user_cheat(mob/living/carbon/human/user)
	return TRUE

/obj/item/deck/proc/populate_deck()
	PROTECTED_PROC(TRUE)

/obj/item/deck/Initialize(mapload)
	. = ..()
	populate_deck()

/obj/item/deck/examine()
	. = ..()
	. += span_notice("It has [cards.len] cards left.")

/obj/item/deck/get_mechanics_examine(mob/user)
	. = ..()
	. += span_smallnotice("I can CLICK-DRAG the deck into my hand slot to pick it up.")
	. += span_smallnotice("I may USE this in my hand to choose whether to shuffle the deck, search it for specific cards to draw, or choose how many cards I wish to deal when dealing a hand.")
	. += span_smallnotice("While holding the deck, I may deal cards with a single CLICK, which throws the card or cards to wherever I am aiming. LEFT CLICK deals a single card. RIGHT CLICK deals a hand of cards instead.")
	. += span_smallnotice("My intents determine whether or not I will deal the cards face-down or face-up.")
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(can_user_cheat(H))
			. += span_smallracialstatinfo("Thanks to Xylix's gifts, I may also CHEAT.")

/obj/item/deck/cards
	name = "deck of playing cards"
	desc = "A deck of simple playing cards inked in the name of one of Xylix's most favored activities."

/obj/item/deck/cards/populate_deck()
	PROTECTED_PROC(TRUE)
	for(var/i = 0, i < deck_size, i++)
		for(var/suit in list("spades","clubs","diamonds","hearts"))
			for(var/number in list("ace","two","three","four","five","six","seven","eight","nine","ten","jack","queen","king"))
				var/datum/playingcard/pcard = new()
				pcard.name = "[capitalize(number)] of [capitalize(suit)]"
				pcard.front_icon_state = "[number]-[suit]"
				pcard.icon = icon
				cards.Add(pcard) // Make it so.

/obj/item/deck/tarot
	name = "tarot deck"
	desc = "The Mouthpiece of Xylix, given to mortals long ago. See fate. Never bend a corner."
	icon = 'icons/roguetown/items/cards/tarot.dmi'

/obj/item/deck/tarot/populate_deck()
	. = ..()

/obj/item/deck/tarot/majorarcana
	name = "tarot deck (major arcana)"

/obj/item/deck/tarot/majorarcana/populate_deck()
	. = ..()

#undef MAX_HAND_SIZE
