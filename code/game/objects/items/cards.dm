#define MAX_HAND_SIZE 10
#define TAROT_DECK_DESCRIPTION "The Mouthpiece of Xylix, given to mortals long ago. See fate. Never bend a corner."

/** Helper proc for card game stuff that prompts the user to choose from a list of cards which selection of cards they wish to draw.
* Returns which cards they wish to draw as `list`.
*/
/obj/item/proc/get_cards_in_selection(list/datum/playingcard/card_list, mob/living/carbon/human/user, max_cards_selectable = 10)
	RETURN_TYPE(/list/datum/playingcard)

	if(user.stat || !Adjacent(user)) return

	if(!ishuman(user))
		return

	if(!card_list.len)
		to_chat(user, span_warning("There are no cards in the deck."))
		return

	. = list()

	// Emote before doing anything so you can't cheat!
	user.visible_message(span_notice("\The [user] looks into \the [src] and searches within it..."))

	// We store the card names as a dictionary with the card name as the key and the number of duplicates of that card.
	// Why, you may ask?
	// Because TGUI list selection UIs do NOT like items with duplicate keys strings. We must give each item a unique key string!
	// This is in other words a workaround to TGUI jank.
	var/list/card_names = list()
	for(var/datum/playingcard/P in card_list)
		var/name = P.name
		// If we haven't yet found any cards with this name...
		if(!card_names[name])
			// ... Add them to a new list, where we'll store any duplicates!
			card_names[name] = list()
		card_names[name] += name

	var/list/cards_to_choose = list()
	for(var/key, value in card_names)
		var/list/L = value
		for(var/i = 0, i < L.len, i++)
			cards_to_choose += "[key] ([i+1])"

	var/list/cards_to_draw = tgui_input_checkboxes(user, "Which cards do you want to retrieve?", "Choose your cards", cards_to_choose, 1, max_cards_selectable)

	if(!LAZYLEN(cards_to_draw))
		user.visible_message(span_notice("\The [user] searches for specific cards in \the [src], but draws none."))
		return

	// Search through our cards for every card the user chose, and remove them from the deck if the name matches!
	for(var/to_draw in cards_to_draw)
		for(var/i = length(card_list), i > 0, i--)
			// Ignore the duplicate number at the end, we just want the card name itself!
			var/TDN = copytext(to_draw, 1, length(to_draw) - 3)
			var/datum/playingcard/P = card_list[i]
			if(TDN == P.name)
				card_list.Cut(i, i+1)
				. += P
				break

	user.visible_message(span_notice("\The [user] searches for specific cards in \the [src], and draws [cards_to_draw.len]."))
	return .

/datum/playingcard
	var/name = "playing card"
	var/front_icon_state = "hand1"
	var/back_icon_state = "singlecard_down"
	/// If this is TRUE, the card will be rendered upside-down.
	var/reversed = FALSE
	var/icon = 'icons/roguetown/items/cards/playingcards.dmi'
	var/obj/item/deck/our_deck

/datum/playingcard/proc/get_card_image(image_loc, is_concealed)
	RETURN_TYPE(/image)
	return image(src.icon, image_loc, is_concealed ? back_icon_state : front_icon_state)

/datum/playingcard/proc/get_card_name()
	return name

// Hand of cards. Holds one or more cards

/obj/item/card_hand
	name = "hand of cards"
	icon = 'icons/roguetown/items/cards/playingcards.dmi'
	icon_state = null
	dropshrink = 0.5
	var/list/datum/playingcard/cards = list()
	/// The original deck we come from. Our cards can ONLY be taken from / put into this deck, and no other.
	var/obj/item/deck/our_deck = null
	var/concealed = TRUE

/obj/item/card_hand/proc/get_drawn_cards(mob/living/carbon/human/H, max_amt_to_draw = null)
	var/list/cards_to_draw = get_cards_in_selection(cards.Copy(), H, max_amt_to_draw || min(cards.len, MAX_HAND_SIZE))
	if(cards_to_draw?.len && Adjacent(H))
		var/list/removed = list()
		for(var/datum/playingcard/card_draw in cards_to_draw)
			for(var/datum/playingcard/PC in cards)
				if(card_draw == PC)
					removed.Add(PC)
					cards.Remove(PC)
					break
		return removed
	else
		return null

/obj/item/card_hand/attackby(obj/item/I, mob/user, params)
	if(!user || !ishuman(user) || user.stat)
		return
	if(istype(I, /obj/item/card_hand))
		var/obj/item/card_hand/CH = I
		if(MAX_HAND_SIZE < (CH.cards.len + cards.len))
			to_chat(user, span_warning("\The [src] can only hold [MAX_HAND_SIZE] cards at most."))
			return
		var/mob/living/carbon/human/H = user
		cards.Add(CH.cards)
		H.visible_message(span_notice("\The [H] joins \the [CH] with [H.p_their()] hand."))
		qdel(CH)
		update_icon()

/obj/item/card_hand/attack_self(mob/user)
	. = ..()
	concealed = !concealed
	update_icon()
	user.visible_message(span_notice("\The [user] [concealed ? "conceals" : "reveals"] [user.p_their()] hand."), span_notice("I [concealed ? "conceal" : "reveal"] my hand."), span_notice("I hear the flipping of card stock."))

/obj/item/card_hand/examine(mob/user)
	. = ..()
	if((!concealed) && cards.len)
		. += "<details><summary>[span_notice("Cards in Hand:")]</summary>"
		for(var/datum/playingcard/C in cards)
			var/image/I = C.get_card_image(user, FALSE)
			. += span_notice("[icon2html(I, user)] [C.get_card_name()]")
		. += "</details>"

/obj/item/card_hand/dropped(mob/user, silent)
	. = ..()
	update_icon(user.dir)

/obj/item/card_hand/attack_right(mob/user)
	. = ..()
	if(!user || !ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.get_num_arms() <= 0)
		to_chat(user, span_danger("WITH WHAT ARMS?"))
		return

	// If we're right clicking with an empty hand, make a new hand!
	var/thing_in_hand = H.get_active_held_item()
	if(!thing_in_hand && cards.len > 1)
		// Take the first card in our hand and give it to the new one
		var/datum/playingcard/PC = cards[1]
		cards.Cut(1, 2)
		var/obj/item/card_hand/CH = new(user.loc, our_deck, list(PC), concealed)
		H.put_in_active_hand(CH)
		if(isturf(loc))
			balloon_alert_to_viewers("1 card drawn...")
		update_icon()
	// If we're right clicking with another hand of cards, do the same thing but we just transfer that hand
	else if(istype(thing_in_hand, /obj/item/card_hand))
		var/obj/item/card_hand/CH = thing_in_hand
		if(CH.our_deck != our_deck)
			to_chat(user, span_warning("These cards come from a different deck. I can't mix them."))
			return
		if(CH.cards.len >= MAX_HAND_SIZE)
			to_chat(user, span_warning("It can only hold [MAX_HAND_SIZE] cards at most."))
			return
		var/datum/playingcard/PC = cards[1]
		cards.Cut(1, 2)
		CH.cards.Insert(1, PC)
		CH.update_icon()
		if(!try_delete_self_if_no_cards())
			if(isturf(loc))
				balloon_alert_to_viewers("1 card drawn...")
			update_icon()

/obj/item/card_hand/ShiftRightClick(mob/user)
	if(!ishuman(user) || user.stat)
		return
	var/mob/living/carbon/human/H = user
	if(H.get_num_arms() <= 0)
		to_chat(user, span_danger("WITH WHAT ARMS?"))
		return
	var/thing_in_hand = H.get_active_held_item()
	// If we're right clicking with an empty hand, make a new hand!
	if(!thing_in_hand && cards.len > 1)
		// Let the user choose which cards to remove
		var/list/drawn_cards = get_drawn_cards(H)
		if(drawn_cards?.len)
			var/obj/item/card_hand/CH = new(user.loc, our_deck, drawn_cards, concealed)
			H.put_in_active_hand(CH)
			if(!try_delete_self_if_no_cards())
				if(isturf(loc))
					balloon_alert_to_viewers("[drawn_cards.len] card[drawn_cards.len > 1 ? "s" : ""] drawn...")
				update_icon()
		return TRUE
	// If we're right clicking with another hand of cards, do the same thing but we just transfer that hand
	else if(istype(thing_in_hand, /obj/item/card_hand))
		var/obj/item/card_hand/CH = thing_in_hand
		if(CH.our_deck != our_deck)
			to_chat(user, span_warning("These cards come from a different deck. I can't mix them."))
			return TRUE
		if(CH.cards.len >= MAX_HAND_SIZE)
			to_chat(user, span_warning("It can only hold [MAX_HAND_SIZE] cards at most."))
			return TRUE
		var/list/drawn_cards = get_drawn_cards(H, min(CH.cards.len, cards.len))
		if(drawn_cards?.len)
			CH.cards.Add(drawn_cards)
			CH.update_icon()
			if(!try_delete_self_if_no_cards())
				if(isturf(loc))
					balloon_alert_to_viewers("[drawn_cards.len] card[drawn_cards.len > 1 ? "s" : ""] drawn...")
				update_icon()
		return TRUE

/obj/item/card_hand/proc/try_delete_self_if_no_cards()
	if(!cards.len)
		qdel(src)
		return TRUE
	return FALSE

/obj/item/card_hand/Destroy()
	QDEL_LIST(cards)
	return ..()

/obj/item/card_hand/update_icon(direction = 0)
	cut_overlays()

	var/card_count = cards.len
	// Sanity check
	if(!card_count)
		return
	if(card_count > 1)
		name = "hand of cards ([card_count])"
		desc = "The inked illustrations, still as ice, await their wielder's moment of glory and fortune."
	else
		name = "playing card"
		desc = "One would be forgiven for the bizarre impulse to flick the card stock in one's hand." // Stimming...

	// If we just have a single card, no need for handling the transform
	if(card_count == 1)
		var/datum/playingcard/P = cards[1]
		var/image/I = P.get_card_image(src, concealed)
		add_overlay(I)
		return

	// If there are multiple cards, determine the min / max distance cards can be from one another
	var/offset = FLOOR(20/card_count, 1)

	var/matrix/M = matrix()
	if(direction)
		// Make the cards visually face direction the player (if any) was facing when we were placed
		switch(direction)
			if(NORTH)
				M.Translate( 0,  0)
			if(SOUTH)
				M.Translate( 0,  4)
			if(WEST)
				M.Turn(90)
				M.Translate( 3,  0)
			if(EAST)
				M.Turn(90)
				M.Translate(-2,  0)

	var/i = 0
	for(var/datum/playingcard/P in cards)
		var/image/I = P.get_card_image(src, concealed)
		// Pixel offsets to keep us visually where a player would expect us to go when placing us on a table
		switch(direction)
			if(SOUTH)
				I.pixel_x = 8-(offset*i)
			if(WEST)
				I.pixel_y = -6+(offset*i)
			if(EAST)
				I.pixel_y = 8-(offset*i)
			else
				I.pixel_x = -7+(offset*i)
		I.transform = M
		add_overlay(I)
		i++

/obj/item/card_hand/pickup(mob/user)
	. = ..()
	update_icon()

/obj/item/card_hand/Initialize(mapload, obj/item/deck/source_deck, list/_cards, concealed = TRUE)
	. = ..()
	if(!source_deck || !_cards?.len)
		qdel(src)
		return
	src.concealed = concealed
	src.our_deck = source_deck
	src.cards.Insert(1, _cards)
	update_icon()

// Card decks

// Abstract card deck. Do not directly spawn this ingame - use one of the subtyes!!
/obj/item/deck
	name = "THE DECK OF IMPOSSIBLE AND BROKEN CARDS"
	desc = "You should not be seeing this. If you see this, report it to a developer!!"
	icon = 'icons/roguetown/items/cards/playingcards.dmi'
	icon_state = "deck_full"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0
	var/list/datum/playingcard/cards = list()
	/// Number of times we will duplicate our deck's contents when created. 2 makes a double sized deck, 3 makes triple sized, etc.
	var/deck_size = 1
	/// How many cards are dealt at a time when our holder deals a hand
	var/hand_size = 5
	/// Icon state used for the backs of the cards this deck provides.
	var/back_icon_state = "singlecard_down"
	/// The number of cards we'll deal when dealing hands at a time.
	var/number_cards_to_deal = 1
	grid_width = 32
	grid_height = 32

/obj/item/deck/proc/get_drawn_cards(mob/living/carbon/human/H, max_amt_to_draw = null)
	var/list/cards_to_draw = get_cards_in_selection(cards.Copy(), H, max_amt_to_draw || min(cards.len, MAX_HAND_SIZE))
	if(cards_to_draw?.len && Adjacent(H))
		var/list/removed = list()
		for(var/datum/playingcard/card_draw in cards_to_draw)
			for(var/datum/playingcard/PC in cards)
				if(card_draw == PC)
					removed.Add(PC)
					cards.Remove(PC)
					break
		return removed
	else
		return null

/// Returns whether or not the given user is able to access cheating mechanics.
/obj/item/deck/proc/can_user_cheat(mob/living/carbon/human/user)
	return TRUE

/obj/item/deck/proc/get_new_deck()
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)
	RETURN_TYPE(/list/datum/playingcard)
	return list()

/obj/item/deck/proc/shuffle_deck(mob/user)
	if(cooldown < world.time - 25)
		cards = shuffle(cards)
		playsound(src, 'sound/items/cardshuffle.ogg', 100, TRUE)
		user.visible_message(span_notice("[user] shuffles the deck."), span_notice("I shuffle the deck."), span_notice("I hear the shuffling of cards."))
		cooldown = world.time

/obj/item/deck/attack_self(mob/user)
	. = ..()
	var/choice = tgui_input_number(user, "How many cards do I want to deal at a time when dealing hands?", "DEALER PREPERATION", 5, MAX_HAND_SIZE, 1)
	if(choice)
		number_cards_to_deal = choice

/obj/item/deck/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(istype(I, /obj/item/card_hand))
		var/obj/item/card_hand/CH = I
		if(CH.our_deck != src)
			to_chat(user, span_warning("[CH.cards.len > 1 ? "These cards" : "This card"] didn't come from this deck!"))
			return
		cards.Add(CH.cards)
		user.visible_message(span_notice("\The [user] returns \the [CH] to \the [src]."), span_notice("I return \the [CH] to \the [src]."))
		qdel(CH)
		return

/obj/item/deck/ShiftRightClick(mob/user)
	if(!ishuman(user) || user.stat)
		return
	var/mob/living/carbon/human/H = user
	if(H.get_num_arms() <= 0)
		to_chat(user, span_danger("WITH WHAT ARMS?"))
		return
	var/thing_in_hand = H.get_active_held_item()
	// If we're right clicking with an empty hand, make a new hand!
	if(!thing_in_hand && cards.len > 1)
		// Let the user choose which cards to remove
		var/list/drawn_cards = get_drawn_cards(H, min(cards.len, MAX_HAND_SIZE))
		if(drawn_cards?.len)
			if(isturf(loc))
				balloon_alert_to_viewers("[drawn_cards.len] card[drawn_cards.len > 1 ? "s" : ""] drawn...")
			var/obj/item/card_hand/CH = new(user.loc, src, drawn_cards, TRUE)
			H.put_in_active_hand(CH)
		return TRUE
	// If we're right clicking with another hand of cards, do the same thing but we just transfer that hand
	else if(istype(thing_in_hand, /obj/item/card_hand))
		var/obj/item/card_hand/CH = thing_in_hand
		if(CH.our_deck != src)
			to_chat(user, span_warning("These cards come from a different deck. I can't mix them."))
			return TRUE
		if(CH.cards.len >= MAX_HAND_SIZE)
			to_chat(user, span_warning("It can only hold [MAX_HAND_SIZE] cards at most."))
			return TRUE
		var/list/drawn_cards = get_drawn_cards(H, min(min(CH.cards.len, cards.len), MAX_HAND_SIZE))
		if(drawn_cards?.len)
			if(isturf(loc))
				balloon_alert_to_viewers("[drawn_cards.len] card[drawn_cards.len > 1 ? "s" : ""] drawn...")
			CH.cards.Add(drawn_cards)
			CH.update_icon()
		return TRUE

/obj/item/deck/attack_right(mob/user)
	. = ..()
	if(!user || !ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.get_num_arms() <= 0)
		to_chat(user, span_danger("WITH WHAT ARMS?"))
		return
	// If we're right clicking with an empty hand, make a new hand!
	var/thing_in_hand = H.get_active_held_item()
	if(!thing_in_hand && cards.len > 1)
		// Take the first card in our hand and give it to the new one
		var/datum/playingcard/PC = cards[1]
		cards.Cut(1, 2)
		var/obj/item/card_hand/CH = new(user.loc, src, list(PC), TRUE)
		H.put_in_active_hand(CH)
		if(isturf(loc))
			balloon_alert_to_viewers("1 card drawn...")
	// If we're right clicking with another hand of cards, do the same thing but we just transfer that hand
	else if(istype(thing_in_hand, /obj/item/card_hand))
		var/obj/item/card_hand/CH = thing_in_hand
		if(CH.our_deck != src)
			to_chat(user, span_warning("These cards come from a different deck. I can't mix them."))
			return
		if(CH.cards.len >= MAX_HAND_SIZE)
			to_chat(user, span_warning("It can only hold [MAX_HAND_SIZE] cards at most."))
			return
		var/datum/playingcard/PC = cards[1]
		cards.Cut(1, 2)
		CH.cards.Insert(1, PC)
		CH.update_icon()
		if(isturf(loc))
			balloon_alert_to_viewers("1 card drawn...")

/obj/item/deck/MiddleClick(mob/user, params)
	. = ..()
	if(!ishuman(user) || user.stat || !user.canUseTopic(src, BE_CLOSE))
		return
	shuffle_deck(user)
	user.changeNext_move(CLICK_CD_MELEE)

/obj/item/deck/Initialize(mapload)
	. = ..()
	for(var/i = 0, i < deck_size, i++)
		var/list/datum/playingcard/new_deck = get_new_deck()
		cards.Insert(1, new_deck)
	cards = shuffle(cards)

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
	desc = "To the Xylixians; sacred. To the rest of the church of the Ten; a source of moral decay."

/obj/item/deck/cards/get_new_deck()
	. = ..()
	for(var/suit in list("spades","clubs","diamonds","hearts"))
		for(var/number in list("ace","two","three","four","five","six","seven","eight","nine","ten","jack","queen","king"))
			var/datum/playingcard/pcard = new()
			pcard.name = "[capitalize(number)] of [capitalize(suit)]"
			pcard.front_icon_state = "[number]-[suit]"
			pcard.back_icon_state = back_icon_state
			pcard.icon = icon
			. += pcard // Make it so.

/obj/item/deck/cards/triple
	name = "triple-sized deck of playing cards"
	deck_size = 3

/obj/item/deck/tarot
	name = "tarot deck (major arcana)"
	desc = TAROT_DECK_DESCRIPTION + " This deck uses only the major arcana."
	icon = 'icons/roguetown/items/cards/tarot.dmi'
	var/has_minor_arcana = FALSE

/obj/item/deck/tarot/includes_minor_arcana
	name = "tarot deck (major and minor arcana)"
	has_minor_arcana = TRUE
	desc = TAROT_DECK_DESCRIPTION + " This deck uses both the major and minor arcana."

/obj/item/deck/tarot/get_new_deck()
	. = ..()
	var/list/major_arcana = alist(
		"The Magician" = "magician",
		"The High Priestess" = "high-priestess",
		"The Empress" = "empress",
		"The Emperor" = "emperor",
		"The Hierophant" = "hierophant",
		"The Lovers" = "lovers",
		"The Chariot" = "chariot",
		"The Hermit" = "hermit",
		"The Wheel of Fortune" = "wheel-of-fortune",
		"The Hanged Man" = "hanged-man",
		"The Devil" = "devil",
		"The Tower" = "tower",
		"The Star" = "star",
		"The Moon" = "moon",
		"The Sun" = "sun",
		"The World" = "world",
		"The Fool" = "fool",
		"Justice" = "justice",
		"Strength" = "strength",
		"Death" = "death",
		"Temperance" = "temperance",
		"Judgement" = "judgement",
	)
	for(var/key, value in major_arcana)
		var/datum/playingcard/pcard = new()
		pcard.name = key
		pcard.front_icon_state = value
		pcard.back_icon_state = back_icon_state
		pcard.icon = icon
		. += pcard
	// If we want the minor arcana too, include that!
	if(has_minor_arcana)
		for(var/suit in list("swords","wands","cups","pentacles"))
			for(var/number in list("ace","two","three","four","five","six","seven","eight","nine","ten","page","knight","queen","king"))
				var/datum/playingcard/pcard = new()
				pcard.name = "[capitalize(number)] of [capitalize(suit)]"
				pcard.front_icon_state = "[number]-[suit]"
				pcard.back_icon_state = back_icon_state
				pcard.icon = icon
				. += pcard


#undef MAX_HAND_SIZE
#undef TAROT_DECK_DESCRIPTION
