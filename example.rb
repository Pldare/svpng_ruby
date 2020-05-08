require_relative 'Svpng.rb'
def test_rgb
	rgb_data=256.times.map{|y| 256.times.map{|x| [x,y,256]}}
	Svpng_rb.new("rgb.png",256,256,rgb_data,false)
end
def test_rgba
	rgb_data=256.times.map{|y| 256.times.map{|x| [x,y,128,(x+y)/2]}}
	Svpng_rb.new("rgba.png",256,256,rgb_data,true)
end
test_rgb
test_rgba