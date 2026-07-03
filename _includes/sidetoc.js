// Initialize scroll bar to the right when the page loads
document.addEventListener('DOMContentLoaded', function() {
    const container = document.getElementById('sidetoc');
    // Use requestAnimationFrame or setTimeout to ensure content is rendered
    // requestAnimationFrame(() => {
    //     // container.scrollLeft = container.scrollWidth;
    //     container.scrollLeft = 0;
    // });
    container.scrollLeft = container.scrollWidth;
    // container.scrollLeft = 0;

    container.addEventListener('wheel', function(e) {
        // Detect if it's a trackpad: small deltaY/deltaX values usually mean trackpad
        const isTrackpad = Math.abs(e.deltaY) < 50 && Math.abs(e.deltaX) < 50;

        // Only reverse horizontal scroll for trackpad events
        if (isTrackpad && e.deltaX !== 0) {
            e.preventDefault(); // Stop default scroll
            // Reverse horizontal scroll direction
            container.scrollLeft -= e.deltaX;
        }
        // Let vertical scroll behave normally
        }, { passive: false });
});