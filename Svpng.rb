############################################################################################
# Copyright (C) 2017 Milo Yip. All rights reserved.
############################################################################################
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
############################################################################################
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
############################################################################################
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and or other materials provided with the distribution.
############################################################################################
# Neither the name of pngout nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
############################################################################################
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
############################################################################################
#svpng is a minimalistic C function for saving RGB or RGBA image into uncompressed PNG.

#example Svpng.new("lpng.png",2,2,[[255,176,128,255],[255,176,128,255],[255,176,128,255],[255,176,128,255]],true)
#参数 生成png的名称 宽 高 像素值(范围 0-255 格式[[r,g,b,a],[r,g,b,a].....]) 是否带透明通道(true : false)
class Svpng_rb
	def initialize(png_name,w,h,rgb_data,alpha)
		@crc_table=256.times.map{|n| 8.times.map{|k| n&1!=0 ? n=0xedb88320^(n>>1) : n=n>>1}[-1]}
		@adler_a=1
		@adler_b=0
		@crc=0
		@pitch=w*(alpha ? 4 : 3) + 1
		@bs=File.open(png_name,"wb")
		
		#main
		u8a("\x89PNG\r\n\32\n")
		p_begin("IHDR",13)
		u32c(w)
		u32c(h)
		u8c(8)#Depth
		u8c(alpha ? 6 : 2)#Color with/without alpha
		u8ac("\x00\x00\x00")#Compression=Deflate, Filter=No, Interlace=No
		p_end
		
		p_begin("IDAT",2+h*(5+@pitch)+4)
		u8ac("\x78\x01")#未使用压缩的头部
		for y in 0...h#一行像素为一块
			u8c(y == h - 1 ? 1 : 0)#1 最后的块 : 0 后续还有块
			u16lc(@pitch)#数据块大小
			u16lc(@pitch^0xffff)#数据块大小按位取反
			u8adler(0)#每块像素开头\x00
			for x in 0...((@pitch-1)/(alpha ? 4 : 3))
				#rgb_info=rgb_data[y*x]#从rgb_data中获取单个像素值
				for i in 0...(alpha ? 4 : 3)
					u8adler(rgb_data[y][x][i])
				end
			end
		end
		u32c((@adler_b<<16)|@adler_a)
		p_end
		
		p_begin("IEND",0)
		p_end
	end
	def u8a(ua)
		@bs.print(ua)
	end
	def u32(u)
		@bs.print [u].pack("N")
	end
	def u8c(u)
		@bs.print [u].pack("C")
		@crc=@crc_table[(@crc^u)&0xff]^(@crc>>8)
	end
	def u8ac(u)
		for i in 0...u.size
			u8c(u[i].unpack("C")[0])
		end
	end
	def u16lc(u)
		u8c(u&255)
		u8c((u>>8)&255)
	end
	def u32c(u)
		u8c(u>>24)
		u8c((u>>16)&255)
		u8c((u>>8)&255)
		u8c(u&255)
	end
	def u8adler(u)
		u8c(u)
		@adler_a=(@adler_a+u)%65521
		@adler_b=(@adler_a+@adler_b)%65521
	end
	def p_begin(u,l)
		u32(l)
		@crc=0xffffffff
		u8ac(u)
	end
	def p_end
		u32(@crc^0xffffffff)
	end
end
