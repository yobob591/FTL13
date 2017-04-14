
#define GASMINER_POWER_NONE 0
#define GASMINER_POWER_STATIC 1
#define GASMINER_POWER_MOLES 2	//Scaled from here on down.
#define GASMINER_POWER_KPA 3
#define GASMINER_POWER_FULLSCALE 4

/obj/machinery/atmospherics/miner
	name = "gas miner"
	desc = "Gasses mined while orbiting a gas giant flow out through this massive vent."
	icon = 'icons/obj/atmospherics/components/miners.dmi'
	icon_state = "miner"
	anchored = 1
	density = 0
	var/spawn_id = null
	var/spawn_temp = T20C
	var/spawn_mol = MOLES_CELLSTANDARD * 10
	var/max_ext_mol = INFINITY
	var/max_ext_kpa = 80000
	var/overlay_color = "#FFFFFF"
	var/active = TRUE
	var/power_draw = 0
	var/power_draw_static = 2000
	var/power_draw_dynamic_mol_coeff = 5	//DO NOT USE DYNAMIC SETTINGS UNTIL SOMEONE MAKES A USER INTERFACE/CONTROLLER FOR THIS!
	var/power_draw_dynamic_kpa_coeff = 0.5
	var/broken = FALSE
	var/broken_message = "ERROR"
	idle_power_usage = 150
	active_power_usage = 2000

/obj/machinery/atmospherics/miner/examine(mob/user)
	..()
	if(broken)
		user << "Its debug output is printing \"[broken_message]\""

/obj/machinery/atmospherics/miner/proc/check_operation()
	if(!active)
		return FALSE
	if(!SSstarmap.current_planet || SSstarmap.current_planet.planet_type != "Gas Giant")
		broken_message = "<span class='boldwarning'>SHIP IS NOT ORBITING A GAS GIANT</span>"
		broken = TRUE
		return FALSE
	var/turf/T = get_turf(src)
	if(!istype(T, /turf/open))
		broken_message = "<span class='boldwarning'>VENT BLOCKED</span>"
		broken = TRUE
		return FALSE
	var/turf/open/OT = T
	if(OT.planetary_atmos)
		broken_message = "<span class='boldwarning'>DEVICE NOT ENCLOSED IN A PRESSURIZED ENVIRONMENT</span>"
		broken = TRUE
		return FALSE
	if(istype(T, /turf/open/space))
		broken_message = "<span class='boldwarning'>AIR VENTING TO SPACE</span>"
		broken = TRUE
		return FALSE
	var/datum/gas_mixture/G = OT.return_air()
	if(G.return_pressure() > (max_ext_kpa - ((spawn_mol*spawn_temp*R_IDEAL_GAS_EQUATION)/(CELL_VOLUME))))
		broken_message = "<span class='boldwarning'>EXTERNAL PRESSURE OVER THRESHOLD</span>"
		broken = TRUE
		return FALSE
	if(G.total_moles() > max_ext_mol)
		broken_message = "<span class='boldwarning'>EXTERNAL AIR CONCENTRATION OVER THRESHOLD</span>"
		broken = TRUE
		return FALSE
	if(broken)
		broken = FALSE
		broken_message = ""
	return TRUE

/obj/machinery/atmospherics/miner/proc/update_power()
	if(!active)
		active_power_usage = idle_power_usage
	var/turf/T = get_turf(src)
	var/datum/gas_mixture/G = T.return_air()
	var/P = G.return_pressure()
	switch(power_draw)
		if(GASMINER_POWER_NONE)
			active_power_usage = 0
		if(GASMINER_POWER_STATIC)
			active_power_usage = power_draw_static
		if(GASMINER_POWER_MOLES)
			active_power_usage = spawn_mol * power_draw_dynamic_mol_coeff
		if(GASMINER_POWER_KPA)
			active_power_usage = P * power_draw_dynamic_kpa_coeff
		if(GASMINER_POWER_FULLSCALE)
			active_power_usage = (spawn_mol * power_draw_dynamic_mol_coeff) + (P * power_draw_dynamic_kpa_coeff)

/obj/machinery/atmospherics/miner/proc/do_use_power(amount)
	var/turf/T = get_turf(src)
	if(T && istype(T))
		var/obj/structure/cable/C = T.get_cable_node() //check if we have a node cable on the machine turf, the first found is picked
		if(C && C.powernet && (C.powernet.avail > amount))
			C.powernet.load += amount
			return TRUE
	if(powered())
		use_power(amount)
		return TRUE
	return FALSE

/obj/machinery/atmospherics/miner/update_icon()
	overlays.Cut()
	if(broken)
		var/image/A = image(icon, "broken")
		add_overlay(A)
	else if(active)
		var/image/A = image(icon, "on")
		A.color = overlay_color
		add_overlay(A)

/obj/machinery/atmospherics/miner/process()
	update_power()
	update_icon()
	check_operation()
	if(active && !broken)
		if(isnull(spawn_id))
			return FALSE
		if(do_use_power(active_power_usage))
			mine_gas()

/obj/machinery/atmospherics/miner/proc/mine_gas()
	var/turf/open/O = get_turf(src)
	if(!istype(O, /turf/open))
		return FALSE
	var/datum/gas_mixture/merger = new
	merger.assert_gas(spawn_id)
	merger.gases[spawn_id][MOLES] = (spawn_mol)
	merger.temperature = spawn_temp
	O.assume_air(merger)
	SSair.add_to_active(O)

/obj/machinery/atmospherics/miner/attack_ai(mob/living/silicon/user)
	if(broken)
		user << "[src] seems to be broken. Its debug interface outputs: [broken_message]"
	..()

/obj/machinery/atmospherics/miner/n2o
	name = "\improper N2O Gas Miner"
	overlay_color = "#FFCCCC"
	spawn_id = "n2o"

/obj/machinery/atmospherics/miner/nitrogen
	name = "\improper N2 Gas Miner"
	overlay_color = "#CCFFCC"
	spawn_id = "n2"

/obj/machinery/atmospherics/miner/oxygen
	name = "\improper O2 Gas Miner"
	overlay_color = "#007FFF"
	spawn_id = "o2"

/obj/machinery/atmospherics/miner/toxins
	name = "\improper Plasma Gas Miner"
	overlay_color = "#FF0000"
	spawn_id = "plasma"

/obj/machinery/atmospherics/miner/carbon_dioxide
	name = "\improper CO2 Gas Miner"
	overlay_color = "#CDCDCD"
	spawn_id = "co2"

/obj/machinery/atmospherics/miner/water_vapor
	name = "\improper Water Vapor Gas Miner"
	overlay_color = "#99928E"
	spawn_id = "water_vapor"