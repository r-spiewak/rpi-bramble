// Global function to calculate element height recursively removing nested hidden nodes
function getVisibleOffsetHeight(element) {
    // Deep clone the element to preserve the original nested structure safely
    const clonedElement = element.cloneNode(true);
    
    // Create an array to track removals and their original next siblings
    let removals = [];

    // Recursive function to strip out all display: none elements
    function removeHiddenNodes(node, removals) {
        console.log("[getVisibleOffsetHeight][removeHiddenNodes] Processing node:", node,"; type:", node.nodeType);
        if (node.nodeType === 1) {  // Element node
            // console.log("[getVisibleOffsetHeight][removeHiddenNodes] computedStyle:", window.getComputedStyle(node));
            // const displayStyle = window.getComputedStyle(node).display;
            console.log("[getVisibleOffsetHeight][removeHiddenNodes] style:", node.style);
            // console.log("[getVisibleOffsetHeight][removeHiddenNodes] 'display: none;' in style:", node.style.contains("display: none;"));
            console.log("[getVisibleOffsetHeight][removeHiddenNodes] style.display:", node.style.display);
            const displayStyle = node.style.display;
            console.log("[getVisibleOffsetHeight][removeHiddenNodes] displayStyle:", displayStyle);
            if (displayStyle === 'none') {
                console.debug("[getVisibleOffsetHeight][removeHiddenNodes] Found 'display: none;' node:", node);
                const parent = node.parentNode;
                if (parent) {
                    const nextSibling = node.nextSibling;
                    console.debug("[getVisibleOffsetHeight][removeHiddenNodes] Removing 'display: none;' node:", node);
                    parent.removeChild(node);
                    // node.height = 0;
                    removals.push({ parent, node, nextSibling });
                }
                return removals;  // Don't process children if the parent is removed
            }
        }
        
        // Process child nodes
        let child = node.firstChild;
        while (child) {
            const next = child.nextSibling;
            removals = removeHiddenNodes(child, removals);
            child = next;
        }
        return removals;
    }

    removals = removeHiddenNodes(clonedElement, removals);

    console.debug("[getVisibleOffsetHeight] number of removals:", removals.length);
    console.debug("[getVisibleOffsetHeight] removals:", removals);

    // Measure the cloned element by temporarily placing it off-screen in the DOM
    clonedElement.style.position = 'absolute';
    clonedElement.style.visibility = 'hidden';
    clonedElement.style.display = 'block';
    // clonedElement.style.display = 'none';
    clonedElement.style.width = window.getComputedStyle(element).width; // Preserve current width constraint for multiline text
    // clonedElement.style.height = 'auto';
    document.body.appendChild(clonedElement);

    // const height = clonedElement.offsetHeight;
    // const height = requestAnimationFrame((clonedElement) => {
    //     const height = clonedElement.offsetHeight;
    //     return height;
    // });
    const height = clonedElement.getBoundingClientRect().height;
    console.debug("[getVisibleOffsetHeight] Element height:", clonedElement.height, " offsetHeight:", clonedElement.offsetHeight);
    console.debug("[getVisibleOffsetHeight] Element:", clonedElement);

    // Cleanup: remove the clone from the DOM
    clonedElement.remove();
    // document.body.removeChild(clonedElement);

    console.debug("[getVisibleOffsetHeight] Element '", element.id, "' height:", height);

    return height;
}

// Global function to calculate element height iteratatively adding children heights
function getVisibleIterativeHeight(submenuElement) {
    let visibleHeight = 0;
    
    for (let child of submenuElement.children) {
        const style = window.getComputedStyle(child);
        
        console.debug("[getVisibleIterativeHeight] ",
            "child:", child,
        );
        // Skip hidden elements
        if (style.display === 'none' || style.visibility === 'hidden') {
            console.debug("[getVisibleIterativeHeight] ",
                "child:", child,
                "display:", style.display,
                "visibility:", style.visibility,
            );
            continue;
        }
        
        // Use getBoundingClientRect for precise height (excludes margins)
        visibleHeight += child.getBoundingClientRect().height;
    }
    
    // Optional: Add margins if you want exact visual height
    // const margin = parseFloat(style.marginTop || 0) + parseFloat(style.marginBottom || 0);
    // visibleHeight += margin;
    
    console.debug("[getVisibleIterativeHeight] height:", visibleHeight);
    return Math.round(visibleHeight);
}

class BarHeightCalculator {
    constructor(container) {
        this.container = container;
        this.measureModeClass = 'js-measuring';
    }

    forceLayoutSync() {
        void this.container.offsetWidth;
    }

    getHeight(node) {
        if (getComputedStyle(node).display === 'none') return 0;
        
        let h = node.offsetHeight;
        // let h = node.scrollHeight;
        // let h = 0;
        console.debug("[BarHeightCalculator][getHeight] scrollHeight:", h);
        
        // // Bottom-up recursion for nested accordions
        // // node.querySelectorAll(':scope > .bar-content-wrapper').forEach(child => {
        // node.querySelectorAll('.bar-content-wrapper').forEach(child => {
        //     console.debug("[BarHeightCalculator][getHeight] child height added.");
        //     h += this.getHeight(child);
        // });
        
        return h;
    }

    getFullHeight() {
        this.forceLayoutSync();
        return this.getHeight(this.container);
    }
}

// Global function to update the bar's height
function updateBarHeight(buttonElement) {
    console.log("[updateBarHeight] called with:", buttonElement);
    // Find the content-wrapper element (the sibling of the bar)
    const searchRootElement = buttonElement.parentElement.parentElement;
    const contentWrapper = searchRootElement.querySelector('.bar-content-wrapper');
    const barElement = searchRootElement.querySelector('.bar');
    console.log(
        "[updateBarHeight] found:",
        "\t\nsearchRootElement:", searchRootElement,
        "\n\tcontentWrapper:", contentWrapper,
        "\n\tbarElement:", barElement,
    );
    
    // Safety check: only run if both elements exist
    if (contentWrapper && barElement) {
        // // Find all hidden children
        // const hiddenChildren = Array.from(contentWrapper.querySelectorAll('[style*="display: none"]'));
        // // Temporarily detach them from the DOM
        // hiddenChildren.forEach(child => child.remove());
        // Get the computed height of the content wrapper
        const computedHeight = contentWrapper.offsetHeight;
        // const computedHeight = getVisibleOffsetHeight(contentWrapper);
        // const computedHeight = getVisibleIterativeHeight(contentWrapper);
        // const computedHeight = new BarHeightCalculator(contentWrapper).getFullHeight();
        // // Restore the children to the parent
        // hiddenChildren.forEach(child => contentWrapper.appendChild(child));
        console.log("[updateBarHeight] computedheight:", computedHeight);
        
        // Apply this height to the bar
        barElement.style.height = computedHeight + 'px';
    }
}

/**
 * Waits for all CSS transitions on the given elements to finish.
 * @param {HTMLElement[]|NodeList} elements - Elements to watch.
 * @returns {Promise<void>} Resolves when all transitions complete.
 */
function waitForAllTransitions(elements) {
    return new Promise((resolve) => {
        if (!elements || elements.length === 0) {
            console.debug("[waitForAllTransitions] No elements passed in.");
            resolve();
            return;
        }

        let remaining = 0;

        elements.forEach(el => {
            const computedStyle = window.getComputedStyle(el);
            const durations = computedStyle.transitionDuration.split(',').map(d => parseFloat(d) || 0);
            const delays = computedStyle.transitionDelay.split(',').map(d => parseFloat(d) || 0);

            // Count only if there is a non-zero transition
            const hasTransition = durations.some(d => d > 0);
            if (!hasTransition) return;

            // Each property with a duration > 0 will trigger transitionend
            const propertyCount = durations.length;
            remaining += propertyCount;

            const onEnd = (e) => {
                // Only count transitions for this element
                if (e.target === el) {
                    remaining--;
                    if (remaining <= 0) {
                        elements.forEach(elem => elem.removeEventListener('transitionend', onEnd));
                        resolve();
                    }
                }
            };

            el.addEventListener('transitionend', onEnd);
        });

        // If no transitions found, resolve immediately
        if (remaining === 0) {
            console.debug("[waitForAllTransitions] No transitions found.");
            resolve();
        } else {
            console.debug("[waitForAllTransitions] Found transitions:", remaining);
        }
    });
}

/**
 * Recursively gets all children of an element.
 * @param {HTMLElement} rootElement - The next element to get the children.
 * @param {HTMLElement[]|NodeList} elements - Elements to watch.
 * @returns {HTMLElement[]|NodeList} The new and updated elements list.
 */
function getAllChildrenElements(rootElement, elements) {
    for (let child of rootElement.children) {
        elements.push(child);
        elements = getAllChildrenElements(child, elements);
    }
    return elements;
}

// Global function to update all bar heights
function updateAllBarHeights() {
    console.debug("[updateAllBarHeights] called.");
    // const rootElement = document.querySelector("sidenav");
    const rootElement = document.getElementById("sidenav");
    if (rootElement) {
        let elements = [];
        // This needs to happen recursively...
        // for (let child of rootElement.children) {
        //     elements.push(child);
        // }
        elements = getAllChildrenElements(rootElement, elements);
        console.debug("[updateAllBarHeights] Number of elements:", elements.length);
        // waitForAllTransitions(elements).then(() => {
            // Find all buttons
            const buttons = rootElement.querySelectorAll('button');
            // Iterate through each button
            // buttons.forEach(button => {
            for (let i = buttons.length -1; i >= 0; i--) {
                let button = buttons[i];
                // console.log(button.textContent);
                updateBarHeight(button);
            }
            // });
        // });
    } else {
        console.error("Root 'sidenav' element not found!")
    }
}

// Global function to toggle accordion (expand/collapse a menu)
function toggleAccordion(id) {
    console.debug("[toggleAccordion] called with:", id);
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
    console.debug("[toggleAccordion] button found:", !!submenu, "accordion found:", !!targetId);
    console.debug("[toggleAccordion] button target:", submenu, "accordion target:", targetId);

    // 2. Toggle the display of the submenu
    if (submenu) {
        const isExpanded = id.classList.contains('expanded');
        console.debug("[toggleAccordion] expanded (before):", isExpanded);
        
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

        console.debug("[toggleAccordion] expanded (after):", id.classList.contains('expanded'));
    }

    // updateBarHeight(submenu);
    setTimeout(() => {
        updateAllBarHeights();
    }, 10);  // A small delay (10ms) forces a reflow/recalculation
}

const resizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
        console.log("[resizeObserver] Observing entry:", entry);
        // Extract the new dimensions
        // const { width, height } = entry.contentRect;
        // console.log(`Container resized to: ${width}px x ${height}px`);
        updateAllBarHeights();
    }
});

// Function to attach resize listener to the main container
function setupResizeListener(containerId) {
    const container = document.getElementById(containerId);
    if (container) {
        // Attach the listener
        // container.addEventListener('resize', () => {
        //     // // You need to wrap a call to your height update function here.
        //     // // Since resize affects *all* bars, you need to loop through all 
        //     // // accordions and trigger the updateBarHeight function for each.
        //     // const allButtons = container.querySelectorAll('.sidebar-item-toggle');
        //     // allButtons.forEach(button => {
        //     //     // Assuming you have a way to pass the button element to the function
        //     //     // that handles the logic for that specific list item.
        //     //     // Re-running the height logic for every button is necessary here.
        //     //     // You may need a helper function that encapsulates the entire
        //     //     // height calculation logic so it can be called repeatedly.
                
        //     //     // Placeholder call:
        //     //     // updateBarHeightForButton(button); 
        //     // });
        //     updateAllBarHeights();
        // });
        resizeObserver.observe(container);
    } else {
        console.error("No 'sidenav' container to observe!")
    }
}

// Initialize bar height when the page loads
document.addEventListener('DOMContentLoaded', function() {
    // // Get the button of the first expandable item
    // const initialButton = document.querySelector('.sidebar-item-toggle');
    // if (initialButton) {
    //     // Run the height update on load
    //     updateBarHeight();
    // }
    updateAllBarHeights();
    // Call this function when the page loads
    setupResizeListener("sidenav"); 
});
