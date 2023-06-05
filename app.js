let currentPage = 0;
let pages = document.querySelectorAll('.page');

function showPage(pageNumber) {
    pages.forEach((page, index) => {
        if (index === pageNumber) {
            page.classList.add('active');
        } else {
            page.classList.remove('active');
        }
    });
}

// Use this function to navigate
function nextPage() {
    if (currentPage < pages.length - 1) {
        currentPage++;
        showPage(currentPage);
    }
}

function prevPage() {
    if (currentPage > 0) {
        currentPage--;
        showPage(currentPage);
    }
}

