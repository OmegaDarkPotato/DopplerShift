/obj/item/melee/baton/doppler_security
	name = "electro baton"
	desc = "A high power baton for incapacitating humans and similar with. Delivers powerful jolts of electricity \
		that may cause bodily harm, but will -- without a doubt -- entice cooperation."

	desc_controls = "<b>Left Click</b> to stun, <b>Right Click</b> to harm."
	wait_desc = "The baton is still charging!"
	context_living_rmb_active = "Harmful Stun"
	attack_verb_continuous = list("beats")
	attack_verb_simple = list("beat")

	icon = 'modular_doppler/modular_weapons/icons/obj/sec_swords.dmi'
	icon_state = "baton_two"
	lefthand_file = 'modular_doppler/modular_weapons/icons/mob/inhands/melee_lefthand.dmi'
	righthand_file = 'modular_doppler/modular_weapons/icons/mob/inhands/melee_righthand.dmi'
	inhand_icon_state = "baton_two"
	icon_angle = -20

	on_stun_sound = 'sound/items/weapons/taserhit.ogg'
	on_stun_volume = 50
	drop_sound = 'sound/items/baton/stun_baton_active_drop.ogg'
	pickup_sound = 'sound/items/baton/stun_baton_active_pickup.ogg'
	sound_vary = TRUE

	active = TRUE
	force = 10
	wound_bonus = 0
	armor_type = /datum/armor/baton_security
	throwforce = 7
	force_say_chance = 50
	stamina_damage = 35 // DOPPLER EDIT - 4 baton crit now (Original: 60)
	knockdown_time = 5 SECONDS
	clumsy_knockdown_time = 15 SECONDS
	cooldown = 2.5 SECONDS

	var/obj/item/stock_parts/power_store/cell
	var/preload_cell_type //if not empty the baton starts with this type of cell
	var/cell_hit_cost = STANDARD_CELL_CHARGE

/obj/item/melee/baton/doppler_security/Initialize(mapload)
	. = ..()
	if(preload_cell_type)
		if(!ispath(preload_cell_type, /obj/item/stock_parts/power_store/cell))
			log_mapping("[src] at [AREACOORD(src)] had an invalid preload_cell_type: [preload_cell_type].")
		else
			cell = new preload_cell_type(src)

/obj/item/melee/baton/doppler_security/get_cell()
	return cell

/obj/item/melee/baton/doppler_security/suicide_act(mob/living/user)
	if(cell?.charge && active)
		user.visible_message(span_suicide("[user] is putting the live [name] right to [user.p_their()] heart! It looks like [user.p_theyre()] trying to commit suicide!"))
		attack(user, user)
		return FIRELOSS
	return

/obj/item/melee/baton/doppler_security/Destroy()
	if(cell)
		QDEL_NULL(cell)
	UnregisterSignal(src, COMSIG_ATOM_ATTACKBY)
	return ..()

/obj/item/melee/baton/doppler_security/examine(mob/user)
	. = ..()
	if(cell)
		. += span_notice("\The [src] is [round(cell.percent())]% charged.")
	else
		. += span_warning("\The [src] does not have a power source installed.")

/obj/item/melee/baton/doppler_security/proc/deductcharge(deducted_charge)
	if(!cell)
		return
	//Note this value returned is significant, as it will determine
	//if a stun is applied or not
	. = cell.use(deducted_charge)

/obj/item/melee/baton/doppler_security/clumsy_check(mob/living/carbon/human/user)
	. = ..()
	deductcharge(cell_hit_cost)

/obj/item/melee/baton/doppler_security/baton_effect(mob/living/target, mob/living/user, modifiers, stun_override)
	if(iscyborg(loc))
		var/mob/living/silicon/robot/robot = loc
		if(!robot || !robot.cell || !robot.cell.use(cell_hit_cost))
			return FALSE
	else if(!deductcharge(cell_hit_cost))
		return FALSE
	stun_override = 0 //Avoids knocking people down prematurely.
	return ..()

/obj/item/melee/baton/doppler_security/additional_effects_non_cyborg(mob/living/target, mob/living/user)
	target.set_jitter_if_lower(40 SECONDS)
	target.set_stutter_if_lower(16 SECONDS)
	if(iscarbon(target))
		var/mob/living/carbon/big_shocker = target
		big_shocker.electrocute_act(10, src, 1, jitter_time = 0 SECONDS, stutter_time = 0 SECONDS, stun_duration = 0 SECONDS)
	else
		target.electrocute_act(10, src, 1)
	SEND_SIGNAL(target, COMSIG_LIVING_MINOR_SHOCK)
	addtimer(CALLBACK(src, PROC_REF(apply_stun_effect_end), target), 2 SECONDS)

/// After the initial stun period, we check to see if the target needs to have the stun applied.
/obj/item/melee/baton/doppler_security/proc/apply_stun_effect_end(mob/living/target)
	var/trait_check = HAS_TRAIT(target, TRAIT_BATON_RESISTANCE) //var since we check it in out to_chat as well as determine stun duration
	if(!target.IsKnockdown())
		to_chat(target, span_warning("Your muscles seize, making you collapse[trait_check ? ", but your body quickly recovers..." : "!"]"))

	if(!trait_check)
		target.Knockdown(knockdown_time)

/obj/item/melee/baton/doppler_security/emp_act(severity)
	. = ..()
	if (!cell)
		return
	if (!(. & EMP_PROTECT_SELF))
		deductcharge(STANDARD_CELL_CHARGE / severity)

/obj/item/melee/baton/doppler_security/loaded //this one starts with a cell pre-installed.
	preload_cell_type = /obj/item/stock_parts/power_store/cell/high
