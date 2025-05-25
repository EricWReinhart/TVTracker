import Sortable from "sortablejs";

let DragHook = {
  mounted() {
    this.sortable = Sortable.create(this.el, {
      animation: 150,
      onEnd: (event) => {
        let ids = Array.from(this.el.children).map((el) => {
          return el.dataset.id;
        });

        this.pushEvent("reorder", { ids: ids });
      }
    });
  },
  destroyed() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  }
};

export default DragHook;
