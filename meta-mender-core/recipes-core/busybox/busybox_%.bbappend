# Ensure Bitbake searches in the current directory for files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# --- Conditional BusyBox Configuration based on CLIENT_RECIPE PACKAGECONFIG ---
# Create a variable to hold any conditional configuration fragments
BUSYBOX_EXTRA_CONF_FRAGMENTS = ""

python () {
    import bb.data
    import bb.utils

    # Define the recipe name we are interested in checking
    CLIENT_RECIPE = "mender"

    # Get the data store for the current (busybox) recipe's context
    d_current = d

    try:
        # Get the PACKAGECONFIG variable specifically for CLIENT_RECIPE from Bitbake's global data store.
        # This will be the *final* PACKAGECONFIG value after all includes (.inc files)
        # and any overrides (from local.conf or other recipes) have been applied.
        client_packgeconfig = bb.data.getVarFlag('PACKAGECONFIG', CLIENT_RECIPE, d_current)

        if client_packgeconfig is None:
            # If PACKAGECONFIG is None, it means the variable wasn't set for CLIENT_RECIPE
            # or the recipe itself might not have been fully parsed yet (less likely if it's in the image).
            bb.warn(f"PACKAGECONFIG for recipe '{CLIENT_RECIPE}' not found in global data. Is '{CLIENT_RECIPE}' part of your build?")
            return

        # Now, check if 'inventory-network-scripts' is in the retrieved PACKAGECONFIG string.
        # bb.data.init_varstring is used to treat the string as a variable context for bb.utils.contains.
        if bb.utils.contains('PACKAGECONFIG', 'inventory-network-scripts', True, False, bb.data.init_varstring(client_packgeconfig)):
            bb.note(f"'{CLIENT_RECIPE}'s PACKAGECONFIG includes 'inventory-network-scripts'. Adding wget to BusyBox.")
            # Append the wget configuration fragment to the variable
            d_current.appendVar('BUSYBOX_EXTRA_CONF_FRAGMENTS', ' file://busybox_wget.cfg')
        else:
            bb.note(f"'{CLIENT_RECIPE}'s PACKAGECONFIG does NOT include 'inventory-network-scripts'. BusyBox wget will not be forced.")

    except Exception as e:
        bb.warn(f"Error checking PACKAGECONFIG for '{CLIENT_RECIPE}': {e}. BusyBox wget configuration might be incorrect.")
        return
}

# Append the conditional fragments to SRC_URI.
# This will add busybox_wget.cfg if the Python logic determined it was needed.
SRC_URI:append = "${BUSYBOX_EXTRA_CONF_FRAGMENTS}"