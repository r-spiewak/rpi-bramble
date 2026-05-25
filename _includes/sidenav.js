function toggleAccordion(id) {
    console.log("toggleAccordion called with:", id);
    // const accordionId = id + "_accordion";
    // const accordion = document.getElementById(id + "_accordion");
    // const button = document.getElementById(id);
    // console.log("button found:", !!button, "accordion found:", !!accordion);

    // if (!accordion) {
    //     console.warn("Accordion element not found:", accordionId);
    //     return;
    // }

    // accordion.classList.toggle("expanded");
    // accordion.classList.toggle("collapsed");

    // if (button) {
    //     button.classList.toggle("expanded");
    //     button.classList.toggle("collapsed");
    // }

    // 1. Find the associated submenu container using the data attribute
    const targetId = id.getAttribute('data-target');
    const submenu = document.getElementById(targetId);
    console.log("button found:", !!submenu, "accordion found:", !!targetId);
    console.log("button target:", submenu, "accordion target:", targetId);

    // 2. Toggle the display of the submenu
    if (submenu) {
        const isExpanded = id.classList.contains('expanded');
        console.log("expanded (before):", isExpanded);
        
        // Logic to hide/show the submenu
        if (isExpanded) {
            submenu.style.display = 'none';
            id.classList.remove('expanded');
            id.setAttribute('aria-expanded', 'false');
        } else {
            submenu.style.display = 'block';
            id.classList.add('expanded');
            id.setAttribute('aria-expanded', 'true');
        }

        console.log("expanded (after):", id.classList.contains('expanded'));
    }
}
