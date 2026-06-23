import os

def clean_file():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_path = os.path.join(script_dir, 'nomenclature_from_1c.csv')
    output_path = os.path.join(script_dir, 'nomenclature_from_1c_clean.csv')
    
    cleaned_rows = []
    
    with open(input_path, 'r', encoding='cp1251', errors='replace') as f:
        # Read lines manually to handle invalid quotes
        header = f.readline().strip()
        cleaned_rows.append("code;name;in_stock_balance;created_at;is_weight")
        
        for line_num, line in enumerate(f, 2):
            line = line.strip()
            if not line:
                continue
            
            # We want to parse this line. Let's find columns.
            # A line is: code;name;in_stock_balance;created_at;is_weight
            # The first column is code (digits).
            # The last 3 columns are in_stock_balance, created_at, is_weight.
            # So we can split by semicolon, but the name column might contain semicolons and/or quotes.
            parts = line.split(';')
            if len(parts) == 5:
                # Standard line, no extra semicolons. Just clean quotes from the name.
                code, name, stock, created, is_weight = parts
                # Strip wrapping quotes if any, and replace internal quotes
                name = name.strip('"').replace('"', '')
                cleaned_rows.append(f"{code};{name};{stock};{created};{is_weight}")
            else:
                # Semicolons inside the name or other columns.
                # Let's extract the first element as code.
                code = parts[0]
                # Let's extract the last 3 elements.
                stock = parts[-3]
                created = parts[-2]
                is_weight = parts[-1]
                # Everything in between is the name.
                name_parts = parts[1:-3]
                name = ";".join(name_parts)
                # Clean quotes and replace internal semicolons with space
                name = name.strip('"').replace('"', '').replace(';', ' ')
                cleaned_rows.append(f"{code};{name};{stock};{created};{is_weight}")

    with open(output_path, 'w', encoding='cp1251') as f:
        for row in cleaned_rows:
            f.write(row + '\n')
            
    print(f"Cleaned {len(cleaned_rows)} rows successfully.")

if __name__ == '__main__':
    clean_file()
