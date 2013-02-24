require "ffi"
module Msieve
  extend FFI::Library
  ffi_lib "libmsieve.so"

  class Msieve_obj < FFI::Struct
    layout :input, :pointer, # the input here
    :factors, :pointer, # output here, as a linked list
    :max_relations, :int # some setting
  end

  class MsieveFactor < FFI::Struct
    layout :factor_type, :int,
    :number, :pointer,
    :next, :pointer
  end

  def Msieve.cast_to_mo(ptr)
    Msieve_obj.new ptr
  end

  def Msieve.cast_to_mf(ptr)
    MsieveFactor.new ptr
  end

  attach_function :msieve_run, [ Msieve_obj ], :void
  attach_function :msieve_obj_new, [:pointer, #buf pt
                                    :int, # flag
                                    :pointer, #fn
                                    :pointer, #fn
                                    :pointer, #fn
                                    :pointer, #seed
                                    :pointer, #seed
                                    :int, # factor lim
                                    :int, # enum cpu
                                    :int, # cache
                                    :int, #cach3
                                    :int, # threads
                                    :int, # gpu
                                    :pointer], :pointer

  attach_function :get_cpu_type, [], :void ## returns cpu type as enum
  attach_function :get_cache_sizes, [:pointer, :pointer], :void
end

class Numeric
  def msieve_factorize(lim=64)
    len=(str=self.to_s.encode("ASCII-8BIT")).length
    bufptr=FFI::MemoryPointer.new(:char, 400).write_string(str, len)
    seed1, seed2 = Array.new(2){FFI::MemoryPointer.new(:int, 1).put_uint32(0, rand(2**32))}
    cpu=0
    cache1, cache2 = Array.new(2){FFI::MemoryPointer.new(:int, 1)}
    Msieve::get_cache_sizes(cache1, cache2)
    cache1, cache2 = [cache1, cache2].map{|p|p.get_uint32(0)}
    p1, p2, p3, p4 = Array.new(4){FFI::MemoryPointer.new(:int, 1)}

    mo=Msieve::msieve_obj_new(bufptr, 0, p1, p2, p3, seed1, seed2, lim, cpu, cache1, cache2, 0, 0, p4)
    Msieve::msieve_run(mo)
    fct=Msieve.cast_to_mf(Msieve.cast_to_mo(mo)[:factors])
    ret=Array.new
    while not fct.null?
      ret.push(fct[:number].read_string.to_i)
      fct=Msieve.cast_to_mf(fct[:next])
    end
    ret
  end
end
