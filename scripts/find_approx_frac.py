import math

def find_fpga_approximation(target, constant_name, max_bit_shift=12):
    denominator = 2 ** max_bit_shift
    theoretical_numerator = target * denominator
    
    center = round(theoretical_numerator)
    
    print(f"{'Numerator':<9} | {'Fraction Value':<15} | {'Absolute Error':<17} | {'Binary Ones Count'}")
    print("-" * 70)
    
    for numerator in range(center - 8, center + 8):
        value = numerator / denominator
        error = abs(target - value)
        binary_rep = bin(numerator)[2:]
        ones_count = binary_rep.count('1')
        
        marker = " <- Chosen approx." if (constant_name == "Pi" and numerator == 12873) else ""
        print(f"{numerator:<9} | {value:<15.9f} | {error:<17.9f} | {ones_count:<17} {marker}")
        
    if constant_name == "Pi":
        selected_numerator = 12873
    else:
        selected_numerator = center
        
    print(f"\nSelected frac ({selected_numerator}/{denominator}):")
    print("-" * 70)
    
    components = []
    n = selected_numerator
    power = max_bit_shift + 2
    
    while n > 0:
        weight = 2 ** power
        if n >= weight:
            exponent = power - max_bit_shift
            components.append(f"2^{exponent}")
            n -= weight
        power -= 1
        
    equation = " + ".join(components)
    print(f"approximated {constant_name} as: ({equation})")

find_fpga_approximation(math.pi, "Pi", max_bit_shift=12)

print("\n" + "="*75 + "\n")

phi = (1 + math.sqrt(5)) / 2
find_fpga_approximation(phi, "Phi", max_bit_shift=10)