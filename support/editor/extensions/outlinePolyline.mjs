function getOffsets(a, b, thickness) {
  var
      dx = b.x - a.x,
      dy = b.y - a.y,
      len = Math.sqrt(dx * dx + dy * dy),
      scale = thickness / (2 * len)
  ;
  return {
      x: -scale * dy,
      y:  scale * dx
  };
}

function getIntersection(a1, b1, a2, b2) {

  // directional constants
  var
      k1 = (b1.y - a1.y) / (b1.x - a1.x),
      k2 = (b2.y - a2.y) / (b2.x - a2.x);



  // if the directional constants are equal, the lines are parallel
  if (Math.abs(k1 - k2)<0.00001) {
      return;
  }

  // y offset constants for both lines
  var m1 = a1.y - k1 * a1.x;
  var m2 = a2.y - k2 * a2.x;

  // compute x
  var x = (m1 - m2) / (k2 - k1);

  // use y = k * x + m to get y coordinate
  var y = k1 * x + m1;

  return { x:x, y:y };
}

function isArray(obj){
  return (Object.prototype.toString.call(obj)==='[object Array]');
}

function me(points, thickness) {


  //Convert points into json notation
  var arr = [];
  for (var i=0; i<points.length; i++){
      var pt = points[i];
      arr.push({
          x: pt[0],
          y: pt[1]
      });
  }
  points = arr;



//Convert thickness into an array as needed
  if (!isArray(thickness)){
      var t = thickness;
      thickness = [];
      for (var i=0; i<points.length; i++){
          thickness.push(t);
      }
  }



  var
      off, off2,
      poly = [],
      isFirst, isLast,
      prevA, prevB,
      interA, interB,
      p0a, p1a, p0b, p1b
  ;

  for (var i = 0, il = points.length - 1; i < il; i++) {
      isFirst = !i;
      isLast = (i === points.length - 2);


      off = getOffsets(points[i], points[i+1], thickness[i]);
      off2 = getOffsets(points[i], points[i+1], thickness[i+1]);

      p0a = { x:points[i].x + off.x, y:points[i].y + off.y };
      p1a = { x:points[i+1].x + off2.x, y:points[i+1].y + off2.y };

      p0b = { x:points[i].x - off.x, y:points[i].y - off.y };
      p1b = { x:points[i+1].x - off2.x, y:points[i+1].y - off2.y };


      if (!isFirst) {
          interA = getIntersection(prevA[0], prevA[1], p0a, p1a);
          if (interA) {
              poly.unshift(interA);
          }
          interB = getIntersection(prevB[0], prevB[1], p0b, p1b);
          if (interB) {
              poly.push(interB);
          }
      }

      if (isFirst) {
          poly.unshift(p0a);
          poly.push(p0b);
      }

      if (isLast) {
          poly.unshift(p1a);
          poly.push(p1b);
      }

      if (!isLast) {
          prevA = [p0a, p1a];
          prevB = [p0b, p1b];
      }
  }


  for (var i=0; i<poly.length; i++){
      var pt = poly[i];
      poly[i] = [pt.x, pt.y];
  }
  poly.push(poly[0]);

  return poly;
}

export function polylineToPolygon(polygon, thickness) {
  var points = polygon.map((pt) => [pt.x, pt.y]);
  tiled.log("Running me:" + points);
  var vertices = me(points, thickness);
  return vertices.map((pt) => Qt.point(pt[0], pt[1]));
}