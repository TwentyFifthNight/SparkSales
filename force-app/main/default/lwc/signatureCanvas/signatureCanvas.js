import { LightningElement, api } from 'lwc';

let isMousePressed, 
    isDotFlag = false,
    prevX = 0,
    currX = 0,
    prevY = 0,
    currY = 0;            
       
let penColor = "#000000"; 
let lineWidth = 1.5;     

let canvasElement, ctx; 
let dataURL, convertedDataURI;

export default class Signature extends LightningElement {
    @api headerText='Sign the invoice';

    @api
    getSignatureData() {
        dataURL = canvasElement.toDataURL("image/jpg");
        convertedDataURI = dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
        return convertedDataURI;
    }

    @api
    clearCanvas(){
        ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);
    }

    addEvents() {
        canvasElement.addEventListener('mousemove', this.handleMouseMove.bind(this));
        canvasElement.addEventListener('mousedown', this.handleMouseDown.bind(this));
        canvasElement.addEventListener('mouseup', this.handleMouseUp.bind(this));
        canvasElement.addEventListener('mouseout', this.handleMouseOut.bind(this));
        canvasElement.addEventListener("touchstart", this.handleTouchStart.bind(this));
        canvasElement.addEventListener("touchmove", this.handleTouchMove.bind(this));
        canvasElement.addEventListener("touchend", this.handleTouchEnd.bind(this));
    }

    handleMouseMove(event){
        if (isMousePressed) {
            this.setupCoordinate(event);
            this.redraw();
        }     
    }

    handleMouseDown(event){
        event.preventDefault();
        this.setupCoordinate(event);           
        isMousePressed = true;
        isDotFlag = true;
        if (isDotFlag) {
            this.drawDot();
            isDotFlag = false;
        }     
    }

    handleMouseUp(event){
        isMousePressed = false;      
    }

    handleMouseOut(event){
        isMousePressed = false;      
    }

    handleTouchStart(event) {
        if (event.targetTouches.length == 1) {
            this.setupCoordinate(event);     
        }
    }


    handleTouchMove(event) {
        event.preventDefault();
        this.setupCoordinate(event);
        this.redraw();
    }

    handleTouchEnd(event) {
        var wasCanvasTouched = event.target === canvasElement;
        if (wasCanvasTouched) {
            event.preventDefault();
            this.setupCoordinate(event);
            this.redraw();
        }
    }

    renderedCallback() {
    canvasElement = this.template.querySelector('canvas');
    ctx = canvasElement.getContext("2d");
    ctx.lineCap = 'round';
    this.addEvents();
    }

    setupCoordinate(eventParam) {
        const clientRect = canvasElement.getBoundingClientRect();
        prevX = currX;
        prevY = currY;
        currX = eventParam.clientX -  clientRect.left;
        currY = eventParam.clientY - clientRect.top;
    }

    redraw() {
        ctx.beginPath();
        ctx.moveTo(prevX, prevY);
        ctx.lineTo(currX, currY);
        ctx.strokeStyle = penColor;
        ctx.lineWidth = lineWidth;        
        ctx.closePath(); 
        ctx.stroke(); 
    }

    drawDot() {
        ctx.beginPath();
        ctx.fillStyle = penColor;
        ctx.fillRect(currX, currY, lineWidth, lineWidth); 
        ctx.closePath();
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}